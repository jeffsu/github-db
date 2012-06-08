class App {
  function initialize() {
    this.issues = JSON.parse($('#data').attr('data')).map(#{ => new Issue($1) });
    this.buildIndeces();
  }

  function buildIndeces() {
    var milestones = this.milestones = { '-1': [] };
    this.issues.forEach(#{ Milestone.fromIssue($1) });
  }
}

class Milestone {
  private {
    var all = {};
  }

  function initialize(name) {
    this.title  = name;
    this.issues = [];
    this.$ele = $('.templates .milestone').clone();
    this.$ele.find('.title').html(this.title);
    $('.milestone-list').append(this.$ele);
    this.$ele.find('.issues').sortable({
      axis: 'y',
      connectWith: '.issues'
    });
  }

  static function all() {
    var ret = [];
    for (var n in all) {
      ret.push(n);
    }
    return ret.sort().reverse().map(#{ => all[$1] });
  }

  function pivot() {
    var $issues = this.$ele.find('.issues');
    this.issues.forEach(#{
      $issues.append($1.$ele);
    });
  }

  static function fromIssue(issue) {
    var m = issue.milestone;
    var n = m ? m.number : '-1';

    var milestone = all[n] = all[n] || new Milestone(m ? m.title : 'Others');
    milestone.issues.push(issue);
  }


}

class Issue {
  private {
    var $issue_;
    var $comment_;
    var $issues;
  }

  function start() {
    if (!$issue_) {
      $issue_   = $('.templates .issue');
      $comment_ = $('.templates .comment');
      $issues   = $('.issue-list');
    }
  }

  function initialize(hash) {
    this.start();
    for (var k in hash) this[k] = hash[k];
    this.$ele = $issue_.clone();
    this.$ele.data('self', this);
    this.$ele.find('.title').html(this.title);

    this.$comments = this.$ele.find('.comments');
    this.comments = this.comments || [];
    this.comments.forEach(#{ self.$comments.append($comment_.clone().html($1.body)); });
    this.$ele.find('.labels').html(this.labels.map(#{ => $1.name }).join(', '));

    $issues.append(this.$ele);
  }

}

class Pivoter {
  function initialize() {

  }

  function pivotMilestone() {
    Milestone.all().forEach(#{ $1.pivot() });
  }

}
