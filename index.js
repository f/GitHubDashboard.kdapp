// Compiled by Koding Servers at Mon Dec 24 2012 04:58:09 GMT-0800 (PST) in server time

(function() {

/* KDAPP STARTS */

/* BLOCK STARTS /Source: /Users/fkadev/Applications/GitHubDashboard.kdapp/app/settings.coffee */

var GitHub;

GitHub = {
  Settings: {
    baseViewClass: 'github-dahsboard',
    appStorageName: 'github-dahsboard',
    requestTimeout: 15000
  },
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


/* BLOCK ENDS */



/* BLOCK STARTS /Source: /Users/fkadev/Applications/GitHubDashboard.kdapp/app/core.coffee */

var Settings, nickname;

Settings = GitHub.Settings;

nickname = KD.whoami().profile.nickname;

GitHub.Core.Storage = (function() {

  Storage.getSingleton = function() {
    var _ref;
    return (_ref = Storage.instance) != null ? _ref : Storage.instance = new Storage;
  };

  function Storage() {
    this.store = new AppStorage(Settings.appStorageName, "0.1");
  }

  Storage.prototype.set = function(key, value) {
    return this.store.setValue(key, value);
  };

  Storage.prototype.get = function(key, callback) {
    return this.store.getValue(key, callback);
  };

  return Storage;

}).call(this);

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

  CLI.getSingleton = function() {
    var _ref;
    return (_ref = CLI.instance) != null ? _ref : CLI.instance = new CLI;
  };

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
    name = name.replace(/.kdapp$/, '');
    path = "/Users/" + nickname + "/Applications/" + name + ".kdapp";
    return this.kite.run("mkdir -p " + path + "; git clone " + url + " " + path, callback);
  };

  return CLI;

}).call(this);

GitHub.Core.Utils = (function() {

  function Utils() {}

  Utils.notify = function(message) {
    return new KDNotificationView({
      title: message
    });
  };

  return Utils;

})();


/* BLOCK ENDS */



/* BLOCK STARTS /Source: /Users/fkadev/Applications/GitHubDashboard.kdapp/app/models.coffee */

var CLI;

CLI = GitHub.Core.CLI;

GitHub.Models.Repo = (function() {

  function Repo(data) {
    this.data = data;
    this.cli = CLI.getSingleton();
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

var Connector, Repo, Settings, Storage, notify, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Settings = GitHub.Settings;

_ref = GitHub.Core, Connector = _ref.Connector, Storage = _ref.Storage;

Repo = GitHub.Models.Repo;

notify = GitHub.Core.Utils.notify;

GitHub.Views.RepoView = (function(_super) {

  __extends(RepoView, _super);

  function RepoView(model) {
    this.model = model;
    alert(JSON.stringify(this.getData()));
  }

  /*
    click: (e)->
      alert 1
      no
      model = new Repo @getData()
  
      if e.target.className is  "clone-app"
          
        notify "Cloning the #{@getData().name} repository as Koding App..."
            
        model.cloneAsApp =>
          notify "#{@getData().name} successfully cloned."
          
      else if e.target.className is "clone"
      
        notify "Cloning the #{@getData().name} repository..."
              
        model.clone =>
          notify "#{@getData().name} successfully cloned."
  */


  return RepoView;

})(JView);

GitHub.Views.ReposView = (function(_super) {

  __extends(ReposView, _super);

  function ReposView() {
    return ReposView.__super__.constructor.apply(this, arguments);
  }

  ReposView.prototype.repos = [];

  ReposView.prototype.resetRepos = function(repos, data) {
    var _this = this;
    $.each(repos, function(repo) {
      return _this.addRepo(repo);
    });
    return this.emit("ResetRepos", this.repos, data);
  };

  ReposView.prototype.addRepo = function(repo, data) {
    var _repo;
    _repo = new Repo(repo);
    this.repos.push(_repo);
    return this.emit("AddRepo", _repo, repo, data);
  };

  ReposView.prototype.viewAppended = function() {};

  return ReposView;

})(JView);

GitHub.Views.MainView = (function(_super) {
  var RepoView, ReposView, _ref1;

  __extends(MainView, _super);

  _ref1 = GitHub.Views, RepoView = _ref1.RepoView, ReposView = _ref1.ReposView;

  function MainView() {
    MainView.__super__.constructor.apply(this, arguments);
    this.github = new Connector;
    this.storage = Storage.getSingleton();
  }

  MainView.prototype.delegateElements = function() {
    var _this = this;
    this.header = new KDHeaderView({
      type: "big",
      title: "Koding GitHub Dashboard"
    });
    this.repoList = new ReposView;
    this.repoList.on("AddRepo", function(repo) {
      var repoView;
      return repoView = new RepoView(repo);
    });
    this.repoList.on("ResetRepos", function(repos, _arg) {
      var username;
      username = _arg.username;
      if (!repos.length) {
        return notify("User " + username + " has no repository. :(");
      }
    });
    this.usernameField = new KDInputView({
      placeholder: "Write a GitHub username.",
      defaultValue: nickname,
      validate: {
        event: "keyup",
        rules: {
          required: true
        }
      }
    });
    this.usernameField.on("ValidationError", function() {
      return _this.usernameButton.disable();
    });
    this.usernameField.on("ValidationPassed", function() {
      return _this.usernameButton.enable();
    });
    return this.usernameButton = new KDButtonView({
      title: "Get User Repositories",
      loader: {
        color: "#000",
        diameter: 16
      },
      callback: function() {
        var username;
        username = _this.usernameField.getValue();
        _this.github.getRepos(username, function(repos) {
          _this.repoList.resetRepos(repos, {
            username: username
          });
          _this.usernameButton.hideLoader();
          return clearTimeout(_this.timeoutListener);
        });
        return _this.timeoutListener = setTimeout(function() {
          notify("Something wrong...");
          return _this.usernameButton.hideLoader();
        }, Settings.requestTimeout);
      }
    });
  };

  MainView.prototype.pistachio = function() {
    return "{{> this.header}}\n{{> this.usernameField}}{{> this.usernameButton}}\n<hr>\n{{> this.repoList}}";
  };

  MainView.prototype.viewAppended = function() {
    this.delegateElements();
    return this.setTemplate(this.pistachio());
  };

  return MainView;

})(JView);


/* BLOCK ENDS */



/* BLOCK STARTS /Source: /Users/fkadev/Applications/GitHubDashboard.kdapp/index.coffee */

var MainView, Settings;

Settings = GitHub.Settings;

MainView = GitHub.Views.MainView;

(function() {
  try {
    return appView.addSubView(new MainView({
      cssClass: Settings.baseViewClass
    }));
  } catch (error) {
    return notify(error);
  }
})();


/* BLOCK ENDS */

/* KDAPP ENDS */

}).call();