"use strict"; 

var express            = require('../express-inherit'),
    winston            = require('winston'),
    Error404           = require('../errors').Error404,
    requireUserOrGuest = require('../apps/auth').requireUserOrGuest,
    image              = require('./image'),
    utils              = require('../utils');


/*

  Generic app for documents. Takes a hash of options that configures it:
  
  var opts = {
    model_name:            'Person',
    template_dir:          'person',
    template_object_name:  'person',
    template_objects_name: 'people',
    url_root:              '/person',
  };
  

*/

module.exports = function (opts) {

  var app = express();

  app.locals({
    image_proxy: utils.image_proxy_helper
  });

  app.get('/', function (req,res,next) {
    var search = req.param('name');
    if (search) {

      req.popit.model(opts.model_name).name_search(search, function(err, names) {
        if (err) return next(err);
        if ( names.length && names.length == 1 ) {
          return res.redirect( opts.url_root + '/' + names[0].slug );
        }
        res.locals.results = names;
        res.render('search.html');
      });

    } else {

      var query = req.popit.model(opts.model_name).find().sort('name');
      query.exec(function(err, docs) {
        if (err) throw err;
        res.locals[opts.template_objects_name] = docs;
        res.render(opts.template_dir + '/index.html');
      });

    }
  });    
  

  app.param('slug', function loadDocumentBySlug (req, res, next, slug) {
    var q = req.popit.model( opts.model_name ).findOne( { slug: slug } );
    if ( opts.model_name == 'Organization' ) {
        q.populate('parent_id');
    }
    q.exec(function(err, doc) {
      if (err) winston.error( err );
      if (!doc) {
        next( new Error404() );
      } else {
        res.locals[opts.template_object_name] = doc;
        req.object = doc;
        next();
      }
    });
  });
  
  
  app.get(  '/:slug/images/upload', requireUserOrGuest, image.upload_image );
  app.post( '/:slug/images/upload', requireUserOrGuest, image.upload_image );
  app.get(  '/:slug/images/:image_spec', image.get );
  app.post( '/:slug/images/:image_spec/delete', requireUserOrGuest, image.delete );


  app.get('/:slug', function(req,res) {
    res.render( opts.template_dir + '/view.html' );
  });

  return app;
};
