exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    // javascripts: {
    //   joinTo: {
    //     "js/app.js": '*.min.js'
    //   }
    // },
    // stylesheets: {
    //   // joinTo: 'css/app.css',
    //   joinTo: {
    //     "css/app.css": '*.min.css'
    //   },
    // },

    javascripts: {
      joinTo: "js/app.js"
    },
    stylesheets: {
      joinTo: {
        "css/app.css": [
          "css/*.scss"
        ]
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "css", "js", "vendor", "skins"],
    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    },
    sass: {
      mode: "native"
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    globals: {
      $: 'jquery',
      jQuery: 'jquery'
    }
  }
}
