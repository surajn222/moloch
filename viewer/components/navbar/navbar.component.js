(function() {

  'use strict';

  /**
   * @class NavbarController
   * @classdesc Interacts with the navbar
   * @example
   * '<navbar></navbar>'
   */
  class NavbarController {

    /**
     * Initialize global variables for this controller
     * @param $location     Exposes browser address bar URL
     *                      (based on the window.location)
     * @param $window       Angular reference to the browser's window object
     * @param molochVersion The installed version of moloch
     *
     * @ngInject
     */
    constructor($location, $window, molochVersion) {
      this.$location      = $location;
      this.$window        = $window;
      this.molochVersion  = molochVersion.version;
    }

    /* Callback when component is mounted and ready */
    $onInit() {
      this.menu = {
        session     : { title: 'Sessions',    link: 'app#/session' },
        spiview     : { title: 'SPI View',    link: 'spiview' },
        spigraph    : { title: 'SPI Graph',   link: 'spigraph' },
        connections : { title: 'Connections', link: 'connections' },
        files       : { title: 'Files',       link: 'files' },
        stats       : { title: 'Stats',       link: 'stats' },
        settings    : { title: 'Settings',    link: 'settings' },
        users       : { title: 'Users',       link: 'users', permission: 'createEnabled' }
      };
    }


    /* exposed functions --------------------------------------------------- */
    /**
     * Determines the active nav item based on the page route
     * @param {string} route The route of the nav item
     */
    isActive(route) {
      return route === 'app#' + this.$location.path();
    }

    /**
     * Redirects to the desired link preserving query parameters
     * @param {string} link The link to redirect to
     */
    navTabClick(link) {
      var path = this.$location.path();
      var fullURL = this.$location.url();
      var urlWithQuery = fullURL.replace(path, link);

      this.$window.location.href = urlWithQuery;
    }

  }

  NavbarController.$inject = ['$location','$window','molochVersion'];

  /**
   * Navbar Directive
   * Displays the navbar
   */
  angular.module('directives.navbar', [])
    .component('navbar', {
      template  : require('html!./navbar.html'),
      controller: NavbarController
    });

})();
