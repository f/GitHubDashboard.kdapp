// Compiled by Koding Servers at Sun Dec 23 2012 22:53:03 GMT-0800 (PST) in server time

(function() {

/* KDAPP STARTS */

/* BLOCK STARTS /Source: /Users/fkadev/Applications/GitHubDashboard.kdapp/app/core.coffee */

var GitHub, nickname;

GitHub = {
  Core: {
    Connector: null,
    CLI: null
  },
  Models: {
    Repo: null
  },
  Views: {
    RepoView: null,
    ReposView: null,
    MainView: null
  }
};

nickname = KD.whoami().profile.nickname;

GitHub.Core.Connector = (function() {

  function Connector() {}

  Connector.prototype.API_ROOT = "https://api.github.com";

  Connector.prototype.request = function(url, callback, data) {
    return $.ajax({
      url: "" + this.API_ROOT + url,
      data: data,
      dataType: "jsonp",
      success: callback
    });
  };

  Connector.prototype.getRepos = function(username, callback, page) {
    var _this = this;
    this.username = username;
    this.page = page != null ? page : 1;
    this.repos || (this.repos = []);
    return this.request("/users/" + username + "/repos", function(response) {
      var data, link, repo, _i, _len, _ref, _ref1;
      _this.meta = response.meta, data = response.data;
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        repo = data[_i];
        _this.repos.push(repo);
      }
      link = (_ref = _this.meta.Link) != null ? _ref[0] : void 0;
      if ((link != null ? (_ref1 = link[1]) != null ? _ref1.rel : void 0 : void 0) === "next") {
        return _this.getRepos(_this.username, callback, _this.page + 1);
      } else {
        return typeof callback === "function" ? callback(_this.repos) : void 0;
      }
    }, {
      page: this.page,
      per_page: 20
    });
  };

  return Connector;

})();

GitHub.Core.CLI = (function() {

  function CLI() {
    this.kite = KD.getSingleton("kiteController");
  }

  CLI.prototype.clone = function(url, name, callback) {
    var path;
    path = "/Users/" + nickname + "/GitHub/" + name;
    return this.kite.run("mkdir -p " + path + "; git clone " + url + " " + path, callback);
  };

  CLI.prototype.cloneAsApp = function(url, name, callback) {
    var path;
    path = "/Users/" + nickname + "/Applications/" + name + ".kdapp";
    return this.kite.run("mkdir -p " + path + "; git clone " + url + " " + path, callback);
  };

  return CLI;

})();


/* BLOCK ENDS */



/* BLOCK STARTS /Source: /Users/fkadev/Applications/GitHubDashboard.kdapp/app/models.coffee */

var CLI;

CLI = GitHub.Core.CLI;

GitHub.Models.Repo = (function() {

  function Repo(data) {
    this.data = data;
    this.cli = new CLI;
  }

  Repo.prototype.clone = function(callback) {
    return this.cli.clone(this.data.clone_url, this.data.name, callback);
  };

  Repo.prototype.cloneAsApp = function(callback) {
    return this.cli.cloneAsApp(this.data.clone_url, this.data.name, callback);
  };

  return Repo;

})();


/* BLOCK ENDS */



/* BLOCK STARTS /Source: /Users/fkadev/Applications/GitHubDashboard.kdapp/app/views.coffee */

var Connector, GITHUB_TIMEOUT, Repo,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Connector = GitHub.Core.Connector;

Repo = GitHub.Models.Repo;

GITHUB_TIMEOUT = 15000;

GitHub.Views.RepoView = (function(_super) {

  __extends(RepoView, _super);

  function RepoView() {
    RepoView.__super__.constructor.apply(this, arguments);
  }

  RepoView.prototype.partial = function(data) {
    return "" + data.name + " - " + data.clone_url + " \n<a class='clone' href='#'>Clone</a> - <a class='clone-app' href='#'>Clone as Koding App</a>";
  };

  RepoView.prototype.click = function(e) {
    var model;
    model = new Repo(this.getData());
    if (e.target.className === "clone-app") {
      new KDNotificationView({
        title: "Cloning the " + (this.getData().name) + " repository as Koding App..."
      });
      return model.cloneAsApp();
    } else if (e.target.className === "clone") {
      new KDNotificationView({
        title: "Cloning the " + (this.getData().name) + " repository..."
      });
      return model.clone();
    }
  };

  return RepoView;

})(KDListItemView);

GitHub.Views.ReposView = (function(_super) {

  __extends(ReposView, _super);

  function ReposView() {
    return ReposView.__super__.constructor.apply(this, arguments);
  }

  return ReposView;

})(KDListView);

GitHub.Views.MainView = (function(_super) {
  var RepoView, ReposView, _ref;

  __extends(MainView, _super);

  _ref = GitHub.Views, RepoView = _ref.RepoView, ReposView = _ref.ReposView;

  function MainView() {
    MainView.__super__.constructor.apply(this, arguments);
    this.github = new Connector;
    this.repoListView = new ReposView;
  }

  MainView.prototype.viewAppended = function() {
    var header, usernameButton, usernameField,
      _this = this;
    header = new KDHeaderView({
      type: "big",
      title: "Koding GitHub Dashboard"
    });
    usernameField = new KDInputView({
      placeholder: "Write a GitHub username.",
      validate: {
        event: "keyup",
        rules: {
          required: true
        }
      }
    });
    usernameField.on("ValidationError", function() {
      return usernameButton.disable();
    });
    usernameField.on("ValidationPassed", function() {
      return usernameButton.enable();
    });
    usernameButton = new KDButtonView({
      title: "Get User Repositories",
      loader: {
        color: "#000",
        diameter: 16
      },
      callback: function() {
        _this.github.getRepos(usernameField.getValue(), function(repos) {
          var repo;
          _this.classListController = new KDListViewController({
            viewOptions: {
              itemClass: RepoView
            }
          }, {
            items: (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = repos.length; _i < _len; _i++) {
                repo = repos[_i];
                if (typeof repo === "object") {
                  _results.push(repo);
                }
              }
              return _results;
            })()
          });
          _this.addSubView(_this.classListController.getView());
          usernameButton.hideLoader();
          return clearTimeout(_this.timeoutListener);
        });
        return _this.timeoutListener = setTimeout((function() {
          new KDNotificationView({
            title: "Something wrong..."
          });
          return usernameButton.hideLoader();
        }), GITHUB_TIMEOUT);
      }
    });
    usernameButton.disable();
    this.addSubView(header);
    this.addSubView(usernameField);
    return this.addSubView(usernameButton);
  };

  return MainView;

})(JView);


/* BLOCK ENDS */



/* BLOCK STARTS /Source: /Users/fkadev/Applications/GitHubDashboard.kdapp/index.coffee */


(function() {
  return appView.addSubView(new GitHub.Views.MainView);
})();


/* BLOCK ENDS */

/* KDAPP ENDS */

}).call();