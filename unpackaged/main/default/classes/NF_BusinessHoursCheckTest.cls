@isTest
public class NF_BusinessHoursCheckTest {
    // @isTest
    // public static void validatebusinessHoursCheck() {
    //     System.debug('Current Time: ' + System.now());
    //     Map<String, object> responseMap;
    //     RestRequest req = new RestRequest();
    //     RestResponse res = new RestResponse();
    //     req.requestURI = '/services/apexrest/nfBusinessHoursCheck/';
    //     req.httpMethod = 'GET';
    //     RestContext.request = req;
    //     RestContext.response = res;
    //     test.startTest();
    //     responseMap = (Map<String, object>) JSON.deserializeUntyped(NF_BusinessHoursCheck.getBusinessHours());
    //     test.stopTest();
    //     system.assertEquals(false, Boolean.valueOf(responseMap.get('isHoliday')));
    //     system.assertEquals(true, Boolean.valueOf(responseMap.get('isOpen')));
    // }
    // @isTest
    // public static void validatebusinessHoursCheck2() {
    //     Map<String, Integer> weekMap = new Map<String, Integer>{
    //         'Monday' => 5,
    //         'Tuesday' => 4,
    //         'Wednesday' => 3,
    //         'Thursday' => 2,
    //         'Friday' => 1,
    //         'Saturday' => 0,
    //         'Sunday' => 6
    //     };
    //     Date today = Date.today();
    //     Date day = Date.today();
    //     today = day.addDays(weekMap.get(string.valueOf(DateTime.now().format('EEEE'))));
    //     System.debug('Current Time: ' + System.now());
    //     BusinessHours defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE];
    //     Holiday hol = new Holiday();
    //     hol.Name = 'TestHoliday';
    //     hol.activitydate = today;
    //     insert hol;
    //     system.debug('holId' + hol.Id);
    //     Map<String, object> responseMap;
    //     RestRequest req = new RestRequest();
    //     RestResponse res = new RestResponse();
    //     req.requestURI = '/services/apexrest/nfBusinessHoursCheck/';
    //     req.httpMethod = 'GET';
    //     RestContext.request = req;
    //     RestContext.response = res;
    //     test.startTest();
    //     responseMap = (Map<String, object>) JSON.deserializeUntyped(NF_BusinessHoursCheck.getBusinessHours());
    //     test.stopTest();
    //     system.assertEquals(false, Boolean.valueOf(responseMap.get('isHoliday')));
    //     system.assertEquals(true, Boolean.valueOf(responseMap.get('isOpen')));
    // }
}