$(#{
  class App {
    function initialize() {
      this.issues = JSON.parse($('#data').attr('data')).map(#{ => new Issue($1) });
      this.issues.forEach(#{ console.log($1.number) });
    }
  }



  class Issue {
    private {
      var $template = $('.templates .issue');
      var $issues   = $('.issues');
    }

    function initialize(hash) {
      for (var k in hash) this[k] = hash[k];
      this.$ele = $template.clone();
      this.$ele.data('self', this);
      $issues.append(this.$ele);
    }

  }
  new App();
});


