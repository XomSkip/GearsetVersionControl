@isTest
public class PSEFormFieldMapperTest {

    // fields returned by the mapper must not have duplicates.
    @isTest
    static void testDashboardPSENamesHasNoDuplicates() {
        Test.startTest();
        
        List<String> fieldNames = PSEFormFieldMapper.getAllPSEFormDashboardFieldNames();
        
        Test.stopTest();

        Set<String> seenNames = new Set<String>();
        for (String fieldName : fieldNames) {
            System.assert(
                !seenNames.contains(fieldName),
                'Found duplicate Field Name: '
                + fieldName
                + ' Please ensure fields are listed either in the BANT form list, OR in the mapped list - never both.'
            );

            seenNames.add(fieldName);
        }
    }

}