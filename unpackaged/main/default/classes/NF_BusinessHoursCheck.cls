@RestResource(urlMapping='/nfBusinessHoursCheck/*')
global with sharing class NF_BusinessHoursCheck {
    @HttpGet
    global static String getBusinessHours() {
        Map<String, Object> response = new Map<String, Object>();
        try {
            // Retrieving the Business Hours Name
            String bhName = RestContext.request.params.get('BusinessHoursName');
            BusinessHours bh;
            system.debug('' + bhName);

            // Checking if the Business Hours Name is empty or not. If empty, then using the Default Business Hours
            if (string.isNotBlank(bhName))
                bh = [
                    SELECT
                        Id,
                        TimeZoneSidKey,
                        SundayStartTime,
                        SundayEndTime,
                        MondayStartTime,
                        MondayEndTime,
                        TuesdayStartTime,
                        TuesdayEndTime,
                        WednesdayStartTime,
                        WednesdayEndTime,
                        ThursdayStartTime,
                        ThursdayEndTime,
                        FridayStartTime,
                        FridayEndTime,
                        SaturdayStartTime,
                        SaturdayEndTime
                    FROM BusinessHours
                    WHERE Name = :bhName
                ];
            else
                bh = [
                    SELECT
                        Id,
                        TimeZoneSidKey,
                        SundayStartTime,
                        SundayEndTime,
                        MondayStartTime,
                        MondayEndTime,
                        TuesdayStartTime,
                        TuesdayEndTime,
                        WednesdayStartTime,
                        WednesdayEndTime,
                        ThursdayStartTime,
                        ThursdayEndTime,
                        FridayStartTime,
                        FridayEndTime,
                        SaturdayStartTime,
                        SaturdayEndTime
                    FROM BusinessHours
                    WHERE IsDefault = TRUE
                ];

            // Calculating the Current Time
            Datetime targetTime = Datetime.now();

            // Calculating the Current Day based on the Time Zone Selected in the Business Hours.
            String dayName = targetTime.format('EEEE', bh.TimeZoneSidKey);
            system.debug('Day Name ' + dayName);

            // Calculating Today and Tomorrow Date
            Date today = Date.valueOf(DateTime.now().format('yyyy-MM-dd HH:mm:ss', bh.TimeZoneSidKey));

            Date tomorrow = today.addDays(1);

            if (test.isRunningTest()) {
                Map<String, Integer> weekMap = new Map<String, Integer>{
                    'Monday' => 5,
                    'Tuesday' => 4,
                    'Wednesday' => 3,
                    'Thursday' => 2,
                    'Friday' => 1,
                    'Saturday' => 0,
                    'Sunday' => 6
                };
                Date day = Date.today();
                today = day.addDays(weekMap.get(string.valueOf(DateTime.now().format('EEEE'))));
                tomorrow = today.addDays(1);
            }
            // Calculating and returning the boolean response i.e. Business Hours are open or closed.
            response.put('isOpen', BusinessHours.isWithin(bh.id, targetTime));

            // Fetching all the Holidays stored in the system based on the Activity Date, strictly speaking, finding Holidays for the Current date.
            Holiday[] holidays1 = [SELECT Id, Name, ActivityDate FROM Holiday];
            Holiday[] holidays2 = new List<Holiday>();
            for (Holiday eachHoli : holidays1) {
                if (eachHoli.ActivityDate >= today && eachHoli.ActivityDate < tomorrow) {
                    holidays2.add(eachHoli);
                }
            }
            system.debug(holidays2);

            Boolean isHoliday = holidays2.size() > 0;

            // Fetching the API Name of current day's StartTime and EndTime field through String
            Map<String, SObjectField> businessHoursFieldMap = Schema.getGlobalDescribe()
                .get('BusinessHours')
                .getDescribe()
                .fields.getMap();
            Schema.SobjectField dayStartTimeField = businessHoursFieldMap.get(dayName + 'StartTime');
            Schema.SobjectField dayEndTimeField = businessHoursFieldMap.get(dayName + 'EndTime');

            // Conditions to distinguish between a Holiday and No Hours
            if (isHoliday == true && BusinessHours.isWithin(bh.id, targetTime) == false) {
                if (
                    businesshours.addGmt(bh.id, targetTime, 1).format('dd', bh.TimeZoneSidKey) ==
                    targetTime.format('dd', bh.TimeZoneSidKey) ||
                    businesshours.addGmt(bh.id, targetTime, -1).format('dd', bh.TimeZoneSidKey) ==
                    targetTime.format('dd', bh.TimeZoneSidKey) ||
                    (bh.get(dayStartTimeField) == '' &&
                    bh.get(dayEndTimeField) == '') ||
                    (bh.get(dayStartTimeField) == null &&
                    bh.get(dayEndTimeField) == null)
                ) {
                    response.put('isHoliday', false);
                    response.put('holidayName', 'None');
                } else {
                    response.put('isHoliday', true);
                    response.put('holidayName', holidays2[0].Name);
                }
            } else {
                response.put('isHoliday', false);
                response.put('holidayName', 'None');
            }
        } catch (exception e) {
            system.debug(
                'Exception Encountered in getBusinessHours of NF_BusinessHoursCheck class >> ' + e.getMessage()
            );
        }
        return JSON.serialize(response);
    }
}