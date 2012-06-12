class App {
  include $m.EventEmitter;

  function initialize() {
    var issues     = JSON.parse($('#data').attr('issues'));
    var milestones = JSON.parse($('#data').attr('milestones'));

    this.storage = new Storage(this, issues, milestones);
    this.filters = new Filters(this.storage);

    this.$issueList     = $('.views > .issue-list');
    this.$milestoneList = $('.views > .milestone-list');
    this.$labelList     = $('.views > .label-list');

    $('.nav-tabs').delegate('li a', 'click', #{
      self.tab($(this).closest('li').prevAll().length);
    });

    this.pivotByMilestones();
    this.toggleEmptyMilestones(false);
  }

  function pivotByLabels() {
    var txt = $('.label-txt').val();
    var labels = txt ? txt.split(',') : [];
    this.tab(1);

    var storage = this.storage;
    var shown = {};

    foreach (var name in labels) {
      var label = storage.labels[name];
      shown[name] = true;
      label.pivot();
      label.show();
    }

    for (var k in storage.labels) {
      var label = storage.labels[k]; 
      if (!shown[k]) label.hide();
    }
  }

  function tab(n) {
    $('.nav li').removeClass('active').eq(n).addClass('active');
    $('.nav-forms>div').addClass('hide').eq(n).removeClass('hide');
    $('.views>table').eq(n).show().siblings().hide();
  }

  function addIssue(issue) {
    this.emit('issue-added', issue);
  }

  function addMilestone(m) {
    this.emit('milestone-added', m);
  }

  function toggleEmptyMilestones(showEmpty) {
    this.storage.milestones.forEach(#{ 
      if ($1.isEmpty()) showEmpty ? $1.show() : $1.hide(); 
    });
  }

  function pivotByMilestones() {
    this.tab(0);
    this.$milestoneList.show().siblings().hide();
    this.storage.milestones.forEach(#{ $1.pivot() });
  }
}

class Label {
  private {
    var templateTxt = <<END
      thead 
        tr
          th(colspan=2).title= name
      tbody.issues-body
        tr.empty
          td(colspan=2) Empty
    END

    var template = jade.compile(templateTxt);
    var $labelList = null;
  }
 
  function initialize(name) {
    if (!$labelList) $labelList = $('table.label-list');

    this.name = name;
    this.issues = [];
    var $ele = $(template(this));

    this.$header = $ele.eq(0);
    this.$body   = $ele.eq(1);
    this.$empty  = $ele.find('.empty');

    $labelList.append(this.$header);
    $labelList.append(this.$body);

    this.$body.sortable({
      axis: 'y',
      connectWith: '.issues-body',
      handle: '.title'
    });

    this.$body.bind('sortreceive', #(evt, ui) {
      ui.item.data('self').setLabel(self);
      self.$empty.hide();
    });

    this.$body.bind('sortremove', #(evt, ui) { 
      ui.item.data('self').removeLabel(self);
      if (self.isEmpty()) self.$empty.show(); 
    });
  }

  function isEmpty() {
    this.$body.find('.issue').length == 0;
  }

  function show() {
    this.$header.show();
    this.$body.show();
  }

  function hide() {
    this.$header.hide();
    this.$body.hide();
  }

  function pivot() {
    $labelList.append(this.$header);
    $labelList.append(this.$body);

    this.issues.forEach(#{ self.$body.append($1.$ele) });

    if (this.issues.length == 0) {
      this.$empty.show();
    } else {
      this.$empty.hide();
    }
  }


}

class Filters {
  function initialize(storage) {
    $('.state').change(#{
      var state = this.value;
      storage.issues.forEach(#(issue) {
        if (state == '') {
          issue.show();          
        } else if (state == issue.state) {
          issue.show();
        } else {
          issue.hide();
        }
      });
    });
  }
}


class Storage {
  function initialize(app, issueData, milestoneData) {
    this.issues = [];

    this.milestones = [];
    this.mLookup = {};
    this.labels  = {};

    foreach (var row in milestoneData) {
      var m = new Milestone(row);
      this.milestones.push(m) 
      this.mLookup[m.number] = m;
    }
    
    var m = new Milestone({ number: '-1', title: '~ Others ~' });
    this.milestones.push(m);
    this.mLookup[m.number] = m;

    foreach (var row in issueData) {
      var issue = new Issue(row);
      this.issues.push(issue);
      app.addIssue(issue);
      issue.labels.forEach(#{
        var label = self.labels[$1] = self.labels[$1] || new Label($1);
        label.issues.push(issue);
      });
      var milestone = this.mLookup[issue.milestone_number || '-1'];
      if (milestone) milestone.issues.push(issue);
    }
  }
}


class Milestone {
  private {
    var templateTxt = <<END
      thead 
        tr.title
          th(colspan=2)= title + ' (' + due_on + ')'
      tbody.issues-body
        tr.empty
          td(colspan=2) Empty
    END

    var template = jade.compile(templateTxt);
    var $milestones = null;
  }

  function initialize(data) {
    if (!$milestones) $milestones = $('.milestone-list');
    for (var k in data) this[k] = data[k];
    this.due_on = (this.due_on || 'NA').replace(/T.*$/, '');

    this.issues = [];

    var $ele = $(template(this));
    this.$header = $($ele[0]);
    this.$body   = $($ele[1]);

    $milestones.append(this.$header);
    $milestones.append(this.$body);

    this.$empty = this.$body.find('.empty').hide();

    this.$body.sortable({
      axis: 'y',
      connectWith: '.issues-body',
      handle: '.title'
    });

    this.$body.bind('sortreceive', #(evt, ui) {
      ui.item.data('self').setMilestone(self);
      self.$empty.hide();
    });

    this.$body.bind('sortstop', #(evt, ui) {
      self.saveOrder();
    });

    this.$body.bind('sortremove', #(evt, ui) { if (self.isEmpty())  self.$empty.show(); });
  }

  function isEmpty() {
    return this.$body.find('.issue').length == 0;
  }

  function hide() {
    this.$header.hide();
    this.$body.hide();
  }

  function show() {
    this.$header.show();
    this.$body.show();
  }


  function saveOrder() {
    var ids = [];
    this.$body.find('.issue').each(#{
      var issue = $(this).data('self');  
      ids.push(issue.number);
    });

    var params = { order: ids.join(',') };
    $.post('/milestones/' + this.number + '/order', params);
  }

  function pivot() {
    var lookup = {};
    this.issues.forEach(#{ lookup[$1.number] = $1 });
    var order = [];
    if (this.issue_order) {
      this.issue_order.forEach(#{ 
        if (lookup[$1]) {
          order.push(lookup[$1])
        }
        delete lookup[$1];
      });
    }

    for (var k in lookup) {
      order.push(lookup[k]);
    }

    order.forEach(#{ self.$body.append($1.$ele); });
    if (this.issues.length == 0) {
     this.$empty.show();
    }
  }
}

class Issue {
  private {
    var templateTxt = <<END
      tr.issue
        td.title= title
        td.comments
        td.labels
    END

    var template = jade.compile(templateTxt);

    var $comment  = null;
    var $issues   = null;
  }

  function initialize(hash) {
    for (var k in hash) this[k] = hash[k];
    this.$ele = $(template(this));
    this.$ele.data('self', this);
    this.labels = this.labels.map(#{ => $1.name });
    this.comments = this.comments || [];
  }

  function setMilestone(milestone) {
    if (this.milestone_number != milestone.number) 
      $.post('/issues/' + this.number, { milestone: milestone.number }, #{
        self.milestone_number = milestone.number; 
      });
  }

  function setLabel(label) {
    var toAdd = true;
    this.labels.forEach(#{ if (label.name == $1) toAdd = false });
    if (toAdd) this.labels.push(label.name);
  }

  function removeLabel(label) {
    this.labels = this.labels.filter(#{ => label.name != $1 }); 
    setTimeout(#{ $.post('/issues/' + self.number, { labels: self.labels.join(',') }); }, 1000);
  }

  function hide() {
    this.$ele.hide();
  }

  function show() {
    this.$ele.show();
  }

}

