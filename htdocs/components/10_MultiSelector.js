// $Revision$

Ensembl.Panel.MultiSelector = Ensembl.Panel.extend({
  constructor: function (id, params) {
    this.base(id);
    this.urlParam = params.urlParam;
    
    Ensembl.EventManager.register('updateConfiguration', this, this.updateSelection);
    Ensembl.EventManager.register('modalPanelResize', this, this.style);
  },
  
  init: function () {
    var myself = this;
    
    this.base();
    
    this.initialSelection = '';
    this.selection        = [];
    
    this.elLk.content = $('.modal_wrapper', this.el);
    this.elLk.list    = $('.multi_selector_list', this.elLk.content);
    
    var ul    = $('ul', this.elLk.list);
    var spans = $('span', ul)
    
    this.elLk.spans    = spans.filter(':not(.switch)');
    this.elLk.form     = $('form', this.elLk.content);
    this.elLk.included = ul.filter('.included');
    this.elLk.excluded = ul.filter('.excluded');
    
    this.setSelection(true);
    
    this.elLk.included.sortable({
      containment: myself.elLk.included.parent(),
      stop: function () { myself.setSelection(); }
    });
    
    this.buttonWidth = spans.filter('.switch').click(function () {
      var li = $(this).parent();
      
      if (li.parent().hasClass('included')) {
        var excluded = $('li', myself.elLk.excluded);
        var i = excluded.length;

        while (i--) {
          if ($(excluded[i]).text() < li.text()) {
            $(excluded[i]).after(li);
            break;
          }
        }
        
        // item to be added is closer to the start of the alphabet than anything in the excluded list
        if (i == -1) {
          myself.elLk.excluded.prepend(li);
        }
        
        myself.setSelection();
        
        excluded = null;
      } else {
        myself.elLk.included.append(li);
        myself.selection.push(li.attr('className'));
      }
      
      li = null;
    }).width();
    
    this.style();
    
    ul = null;
  },
  
  style: function () {
    var width = 0;
    
    this.elLk.spans.each(function () {
      var w = $(this).width();

      if (w > width) {
        width = w;
      }
    });
    
    this.elLk.list.width('');
    this.elLk.list.width(this.elLk.list.width() <= width + this.buttonWidth ? '100%' : '');
  },
  
  setSelection: function (init) {
    this.selection = $.map($('li', this.elLk.included), function (li, i) {
      return li.className;
    });
    
    if (init === true) {
      this.initialSelection = this.selection.join(',');
    }
  },
  
  updateSelection: function () {
    var params = [];
    var i;
    
    for (i = 0; i < this.selection.length; i++) {
      params.push(this.urlParam + (i + 1) + '=' + this.selection[i]);
    }
    
    if (this.selection.join(',') != this.initialSelection) {
      Ensembl.redirect(this.elLk.form.attr('action') + '?' + Ensembl.cleanURL(this.elLk.form.serialize() + ';' + params.join(';')));
    }
    
    return true;
  }
});