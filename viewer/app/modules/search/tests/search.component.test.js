(function() {

  'use strict';

  describe('Search Component ->', function() {

    // load modules
    beforeEach(angular.mock.module('moloch'));
    beforeEach(angular.mock.module('directives.search'));
    beforeEach(angular.mock.module('moloch.util'));

    var scope, search, templateAsHtml, $httpBackend;

    // Initialize and a mock scope
    beforeEach(inject(function(
      _$httpBackend_,
      $componentController,
      $rootScope,
      $compile,
      $location) {

      $httpBackend = _$httpBackend_;

      $httpBackend.expectGET('molochclusters').respond({});

      $httpBackend.expectGET('titleconfig').respond('');

      $httpBackend.expectGET('currentUser').respond({});

      $httpBackend.expectGET('fields').respond({});

      scope = $rootScope.$new();
      var htmlString = '<moloch-search></moloch-search>';

      var element   = angular.element(htmlString);
      var template  = $compile(element)(scope);

      scope.$digest();

      templateAsHtml = template.html();

      search = $componentController('molochSearch', {
        $scope      : scope,
        $routeParams: {},
        $location   : $location
      });

      // spy on emit event
      spyOn(scope, '$emit').and.callThrough();
      spyOn(search.$location, 'search').and.callThrough();

      // initialize search component controller
      search.$onInit();
      $httpBackend.flush();
    }));

    afterEach(function() {
      $httpBackend.verifyNoOutstandingExpectation();
      $httpBackend.verifyNoOutstandingRequest();
    });

    it('should exist and have dependencies', function() {
      expect(search).toBeDefined();
      expect(search.$scope).toBeDefined();
      expect(search.$routeParams).toBeDefined();
      expect(search.$location).toBeDefined();
    });

    it('should render html', function() {
      expect(templateAsHtml).toBeDefined();
    });

    it('should emit a "change:search" event when time range is changed', function() {
      var callCount = 2;

      function changeTimeRange(timeRange) {
        search.timeRange = timeRange;
        search.changeTimeRange();

        expect(scope.$emit).toHaveBeenCalled();

        callCount = callCount + 4;
        expect(search.$location.search.calls.count()).toBe(callCount);
        expect(search.$location.search).toHaveBeenCalledWith('date', timeRange);
      }

      changeTimeRange(1);
      changeTimeRange(6);
      changeTimeRange(24);
    });

    it('should emit a "change:search" event when start or stop time is changed', function() {
      var callCount = 2;

      function changeDate(stopTime, startTime) {
        search.stopTime   = stopTime;
        search.startTime  = startTime;
        search.changeDate();

        expect(scope.$emit).toHaveBeenCalled();

        callCount = callCount + 4;
        expect(search.$location.search.calls.count()).toBe(callCount);
        expect(search.$location.search).toHaveBeenCalledWith('startTime', (startTime/1000).toFixed());
        expect(search.$location.search).toHaveBeenCalledWith('stopTime', (stopTime/1000).toFixed());
      }

      changeDate(1473775168701, 1473773809000);
      changeDate(1473083968701, 1473071809000);
      changeDate(1472829659701, 1472738480000);
    });

    it('should emit a "change:search" event when strictly flag is changed', function() {
      var callCount   = 2;
      search.strictly = false;

      function changeBounded(bounded) {
        search.timeRange  = 1;
        search.strictly   = bounded;
        search.changeBounded();

        var currentTime = new Date().getTime();

        expect(scope.$emit).toHaveBeenCalled();

        callCount = callCount + 2;
        expect(search.$location.search.calls.count()).toBe(callCount);
        if (!bounded) {
          expect(search.$location.search).toHaveBeenCalledWith('strictly', 'true');
        } else {
          expect(search.$location.search).toHaveBeenCalledWith('strictly', null);
        }
      }

      changeBounded(true);
      changeBounded(false);
      changeBounded(true);
    });

    it('should not emit a "change:search" event when start or stop time is invalid', function() {
      var callCount = 2;

      function changeDate(stopTime, startTime) {
        search.stopTime   = stopTime;
        search.startTime  = startTime;
        search.changeDate();

        expect(search.$location.search.calls.count()).toBe(callCount);
      }

      changeDate(1473775168701, 'asdf');
      changeDate('asdf', 1473071809000);
    });

  });

})();
