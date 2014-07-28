"use strict";

var express = require('../express-inherit');
var passport = require('../passport');

var app = module.exports = express();

app.get('/login', function(req, res, next) {
  res.locals.email = req.param('email');
  res.locals.errors = [];

  res.render('login.html');
});

app.post('/login', function(req, res, next) {
  var errors = res.locals.errors = [];
  res.locals.email = req.param('email') || '';

  passport.authenticate('local', function(err, user, info) {
    if (err) {
      return next(err);
    }
    if (!user) {
      errors.push(info.message);
      return res.render('login.html');
    }
    req.login(user, function(err) {
      if (err) {
        return next(err);
      }
      res.locals.user = user;

      var redirect_to = req.session.post_login_redirect_to || '/instances';
      delete req.session.post_login_redirect_to;
      req.flash('info', 'You are now logged in.');
      res.redirect(redirect_to);
    });
  })(req, res, next);
});

app.get('/logout', function(req, res, next) {
  req.session = null;
  res.redirect('/');
});