"use strict";

var generic_document_app      = require('./generic_document'),
    _                         = require('underscore'),
    async                     = require('async'),
    mongoose                  = require('mongoose'),
    user                      = require('../authorization');

module.exports = function () {

  var opts = {
    model_name:            'Person',
    template_dir:          'person',
    template_object_name:  'person',
    template_objects_name: 'people',
    url_root:              '/persons',
  };


  var app = generic_document_app(opts);

  app.routes.get = _.reject(
    app.routes.get,
    function (route) { return route.path === '/:id(*)'; }
  );

  app.get(
    '/new',
    function(req,res) {
        var Person = req.popit.model( opts.model_name );
        res.locals[opts.template_object_name] = new Person();
        res.render( opts.template_dir + '/new.html' );
    }
  );

  app.get('/:id(*)/edit', user.can('edit instance'), function(req, res, next) {
    res.render( opts.template_dir + '/edit.html' );
  });

  app.get('/:id(*)', function(req, res) {
    res.render( opts.template_dir + '/view.html' );
  });

  // Process person's memberships
  app.put('/:id(*)', user.can('edit instance'), function(req, res, next) {
    var memberships = req.body.memberships;
    if (!memberships) {
      return next();
    }
    delete req.body.memberships;

    var Organization = req.db.model('Organization');
    var Membership = req.db.model('Membership');

    var updateMembership = function(membership, done) {
      Membership.findById(membership.id, function(err, doc) {
        if (err) {
          return done(err);
        }
        if (!doc) {
          var objectId = new mongoose.Types.ObjectId();
          doc = new Membership({_id: objectId.toHexString()});
        }
        doc.set(membership);
        doc.save(done);
      });
    };

    async.forEachSeries(memberships, function(membership, done) {
      Organization.findById(membership.organization_id, function(err, organization) {
        if (err) {
          return done(err);
        }
        // Create organization if it doesn't exist, unless there is a post_id becuase
        // you can have post based memberships that don't have orgs. We're safe to do
        // this because the UI does not allow adding post based memberships so there's
        // no chance this is a new membership with a new org.
        if (!organization && !membership.post_id) {
          var objectId = new mongoose.Types.ObjectId();
          organization = new Organization({_id: objectId.toHexString(), name: membership.organization_name});
          membership.organization_id = organization._id;
          delete membership.organization_name;
          organization.save(function(err) {
            if (err) {
              return done(err);
            }

            updateMembership(membership, done);
          });
        } else {
          delete membership.organization_name;
          updateMembership(membership, done);
        }

      });
    }, next);
  });

  // Save changes to person model
  app.put('/:id(*)', user.can('edit instance'), function(req, res, next) {
    var Person = req.db.model('Person');
    Person.findById(req.param('id'), function(err, person) {
      if (err) {
        return next(err);
      }
      person.set(req.body);
      /* we need to explicitely remove these if they are undefined
       * as .set will not remove existing data which means it will
       * never delete a single entry or all entries */
      [
        'other_names',
        'contact_details',
        'memberships',
        'identifiers',
        'links'
      ].forEach(function(field) {
        if ( req.body[field] === undefined ) {
          person[field] = undefined;
        }
      });
      person.save(function(err, person) {
        if (err) {
          return next(err);
        }
        if ( req.param('_add_another') == 1 ) {
          res.redirect('/persons/new');
        } else {
          // there is a bug that means we sometimes failed to create the id
          // key so fallback to _id if that's the case
          var id = person.id ? person.id : person._id;
          res.redirect('/persons/' + encodeURIComponent(id));
        }
      });
    });
  });

  return app;
};
