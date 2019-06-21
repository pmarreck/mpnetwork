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
      joinTo: {
        "js/app.js": [
          "js/*.js",
          /^node_modules/
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": [
          "css/*.scss",
          /^node_modules/
        ],
        "css/public_listing.css": [
          "css/public_listing.css"
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

  notifications: {
    levels: ['error', 'warn', 'info']
  },

  npm: {
    enabled: true,
    globals: {
      $: 'jquery',
      jQuery: 'jquery'
    },
    styles: {
      bootstrap: ["dist/css/bootstrap.min.css"],
      'admin-lte': ["dist/css/AdminLTE.min.css", "dist/css/skins/_all-skins.min.css"],
      select2: ["dist/css/select2.min.css"],
      'bootstrap-datepicker': ["dist/css/bootstrap-datepicker3.min.css"],
      'bootstrap-daterangepicker': ["daterangepicker.scss"],
      quill: ["dist/quill.core.css", "dist/quill.snow.css"],
      'bootstrap-table': ["dist/bootstrap-table.min.css"],
      dropzone: ["dist/dropzone.css"]
    }
  }
}
