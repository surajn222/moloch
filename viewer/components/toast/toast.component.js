(function() {

  'use strict';

  let timeout;

  /**
   * @class ToastController
   * @classdesc Interacts with the toast message
   *
   * @example
   * '<toast message="'Important message!'" type="'success'"></toast>'
   */
  class ToastController {

    /*
     * Initialize global variables for this controller
     * @param $timeout
     *
     * @ngInject
     */
    constructor($timeout) {
      this.$timeout = $timeout;
    }

    /* Callback when component is mounted and ready */
    $onInit() {
      // show alert only if message exists
      this.visible = this.message !== undefined;

      // default type is info
      if (!this.type) { this.type = 'info'; }

      // only display the alert for a time
      this.dismissAfter();
    }

    /* Watch for changes to bindings */
    $onChanges(changes) {
      if (changes.message) {
        if (changes.message.currentValue &&
            changes.message.currentValue !== changes.message.previousValue) {
          this.visible = true;
          this.dismissAfter();
        }
      }
    }


    /* exposed functions --------------------------------------------------- */
    /* Dismisses/closes the toast */
    dismiss() {
      this.message = undefined;
      this.visible = false;
    }

    /* Dismisses the toast after a set duration */
    dismissAfter() {
      this.$timeout.cancel(timeout);

      timeout = this.$timeout(() => {
        this.dismiss();
      }, this.duration || 5000);
    }

  }

  ToastController.$inject = ['$timeout'];

  /**
   * Toast Directive
   * Displays a message for an amount of time
   */
  angular.module('directives.toast', [])
     .component('toast', {
       template  : require('html!./toast.html'),
       controller: ToastController,
       bindings  : {
         message : '<', // message to display in toast
         duration: '<', // duration that toast is displayed
         type    : '<'  // type of toast (danger, warning, success, info)
       }
     });

})();
