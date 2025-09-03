@isTest
public class utm_BU_AdvancedSearchControllerTest {
    
    @isTest
    static void testUtmSearchJobs_withKeyword() {
        Account account = new Account(Name = 'テストアカウント');
        insert account;

        JobOffer__c jobOffer = new JobOffer__c(
            Field1585__c = '時給',
            Salary01__c = 1200,
            SurroundingFacilities__c = '福井駅',
            Field1908__c = '日',
            Field1702__c = 'テスト求人',
            Account__c = account.Id,
            Field1799__c ='テスト求人',
            Field1608__c ='',
            Field1685__c = false,
            OK__c = false,
            Field1623__c = false
        );
        insert jobOffer;

        JobOffer_BU__c job = new JobOffer_BU__c(
            Name = jobOffer.Field1702__c,
            joboffer__c = jobOffer.Id
        );
        insert job;

        Test.startTest();
        List<JobOffer_BU__c> results = utm_BU_AdvancedSearchController.utm_BU_searchJobs(
            'テスト求人',
            new List<String>(),             // jobTypes
            new List<String>{'日'},         // holidays
            new List<String>(),             // workstyle
            new List<String>(),             // employmentTypes
            (Decimal)null,                  // minWage
            (Decimal)null,                  // maxWage
            (String)null,                   // startTimeStr
            (String)null,                   // endTimeStr
            false                           // experienceApplication
        );
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size());
    }

    @isTest
    static void testUtmSearchJobs_withHolidaysOnly() {
        Account account = new Account(Name = 'テストアカウント');
        insert account;

        JobOffer__c jobOffer = new JobOffer__c(
            Field1585__c = '時給',
            Salary01__c = 1300,
            Field1591__c = 1400,
            SurroundingFacilities__c = '福井駅',
            Field1908__c = '日',
            Account__c = account.Id,
            Field1799__c ='テスト求人',
            Field1608__c ='',
            Field1685__c = false,
            OK__c = false,
            Field1623__c = false
        );
        insert jobOffer;

        JobOffer_BU__c job = new JobOffer_BU__c(
            Name = 'コンサルタント求人',
            joboffer__c = jobOffer.Id
        );
        insert job;

        Test.startTest();
        List<JobOffer_BU__c> results = utm_BU_AdvancedSearchController.utm_BU_searchJobs(
            'テスト求人',
            new List<String>(),             // jobTypes
            new List<String>{'日'},         // holidays
            new List<String>(),             // workstyle
            new List<String>(),             // employmentTypes
            (Decimal)null,                  // minWage
            (Decimal)null,                  // maxWage
            (String)null,                   // startTimeStr
            (String)null,                   // endTimeStr
            false                           // experienceApplication
        );
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size());
    }

    @isTest
    static void testUtmSearchJobs_withNoResults() {
        Account account = new Account(Name = 'テストアカウント');
        insert account;

        JobOffer__c jobOffer = new JobOffer__c(
            Field1585__c = '時給',
            Salary01__c = 1400,
            Field1591__c = 1500,
            SurroundingFacilities__c = '福井駅',
            Field1908__c = '祝',
            Account__c = account.Id,
            Field1799__c ='テスト求人',
            Field1608__c ='',
            Field1685__c = false,
            OK__c = true,
            Field1623__c = false
        );
        insert jobOffer;

        JobOffer_BU__c job = new JobOffer_BU__c(
            Name = '違う求人',
            joboffer__c = jobOffer.Id
        );
        insert job;

        Test.startTest();
        List<JobOffer_BU__c> results = utm_BU_AdvancedSearchController.utm_BU_searchJobs(
            'ABY',
            new List<String>(),             // jobTypes
            new List<String>{'A'},          // holidays
            new List<String>(),             // workstyle
            new List<String>{'未経験OK'},   // employmentTypes
            (Decimal)null,                  // minWage
            (Decimal)null,                  // maxWage
            (String)null,                   // startTimeStr
            (String)null,                   // endTimeStr
            false                           // experienceApplication
        );
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @isTest
    static void testUtmSearchJobs_withStartTimeOnly() {
        Account account = new Account(Name = 'テストアカウント'); 
        insert account;
        
        JobOffer__c jobOffer = new JobOffer__c(
            Field1702__c = '時間テスト',
            BusinessContent__c = '営業',
            Field1660__c = Time.newInstance(8, 0, 0, 0),
            Field1663__c = Time.newInstance(18, 0, 0, 0),
            SurroundingFacilities__c = '福井駅',
            Account__c = account.Id,
            Field1623__c = false
        );
        insert jobOffer;
        
        JobOffer_BU__c job = new JobOffer_BU__c(
            Name = '時間テスト', 
            joboffer__c = jobOffer.Id
        );
        insert job;

        Test.startTest();
        List<JobOffer_BU__c> results = utm_BU_AdvancedSearchController.utm_BU_searchJobs(
            '時間テスト',
            new List<String>{'営業'},       // jobTypes
            new List<String>(),             // holidays
            new List<String>(),             // workstyle
            new List<String>(),             // employmentTypes
            (Decimal)null,                  // minWage
            (Decimal)null,                  // maxWage
            '08:00',                        // startTimeStr
            '18:00',                        // endTimeStr
            false                           // experienceApplication
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size());
    }
    
    // 体験応募フィルタのテスト（フィールドに値を設定せずロジックのみテスト）
    @isTest
    static void testUtmSearchJobs_experienceApplicationLogic() {
        Account account = new Account(Name = 'テストアカウント');
        insert account;

        JobOffer__c jobOffer = new JobOffer__c(
            Field1585__c = '時給',
            Salary01__c = 1200,
            Field1702__c = 'ロジックテスト求人',
            Account__c = account.Id,
            Field1799__c = 'ロジックテスト求人',
            Field1608__c = '',
            Field1685__c = false,
            OK__c = false,
            Field1623__c = false
            // Field1864__cは設定しない（nullまたはデフォルト値）
        );
        insert jobOffer;

        JobOffer_BU__c job = new JobOffer_BU__c(
            Name = jobOffer.Field1702__c,
            joboffer__c = jobOffer.Id
        );
        insert job;

        Test.startTest();
        // 体験応募フィルタを true に設定してテスト
        List<JobOffer_BU__c> results = utm_BU_AdvancedSearchController.utm_BU_searchJobs(
            'ロジックテスト求人',
            new List<String>(),             // jobTypes
            new List<String>(),             // holidays
            new List<String>(),             // workstyle
            new List<String>(),             // employmentTypes
            (Decimal)null,                  // minWage
            (Decimal)null,                  // maxWage
            (String)null,                   // startTimeStr
            (String)null,                   // endTimeStr
            true                            // experienceApplication = true
        );
        Test.stopTest();

        // 体験応募フィルタを true にしたので、
        // Field1864__c が '体験応募' でない求人は除外されるため、結果は0件になる
        System.assertEquals(0, results.size());
    }
}