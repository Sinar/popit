define(
  [
    'jquery',
    'Backbone',
    'backbone-forms',
    'underscore',
    'utils/slugify',
    'text!templates/organization/new.html',
    'instance-admin/models/organization',
    'instance-admin/views/submit-form-helper',
    'instance-admin/views/suggestions'
  ],
  function (
    $,
    Backbone,
    BackboneForms,
    _,
    slugify,
    orgTemplate,
    OrganizationModel,
    submitFormHelper,
    SuggestionsView
  ) {
    "use strict"; 

    var OrganizationNewView = Backbone.View.extend({
  
      orgTemplate: _.template(orgTemplate),

      initialize: function () {
        this.form = new BackboneForms({
					model: this.model,
					fields: ['name', 'slug']
				});
        this.suggestionsView = new SuggestionsView({ url_type: 'organizations' });
        
        this.suggestionsView.collection.url = '/autocomplete/organizations';
      },
      
      render: function () {
  
        // render the template and form
        var $content = $( this.orgTemplate() );
        var $form    = $( this.form.render().el );
  
        // add the contents of the form to the template content
        $content.find('form').prepend( $form.children() );
        
        // update our element
        this.$el.html( $content );
  
        // give the list to the Suggestions view for rendering
        this.$('ul.suggestions').html( this.suggestionsView.render().el );
  
        return this;
      },
      
      events: {
        'submit form ':             'submitForm',
        'keyup input[name=name]':   'nameEdit'
      },
      
      submitForm: submitFormHelper({ type: 'organizations' }),
      
      nameEdit: function (e) {
        // When the name is being entered we should fill in the slug. This will
        // let the user edit the slug, or see that it can't be generated from the
        // name. Also means that we don't need to explain why that field is there.
        var $name = this.$(':input[name=name]');
        var $slug = this.$(':input[name=slug]');
        $slug.val( slugify( $name.val() ) );
                
        // Try to load matching people from the server and display them in the
        // 'possible matches' list.
        var self = this;

        self.suggestionsView.setName($name.val());              
  
        return true;
      }
  
    });
  
    return OrganizationNewView;
  
  }
);
