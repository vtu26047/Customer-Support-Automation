public with sharing class CustomerAPIService {

    public class CustomerRequest {
        @InvocableVariable(required=true)
        public Integer customerId;

        @InvocableVariable(required=true)
        public Id caseId;
    }

    @InvocableMethod(label='Fetch Customer Details')
    public static void fetchCustomer(List<CustomerRequest> requests) {

        for (CustomerRequest req : requests) {

            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint('callout:Customer_API/users/' + req.customerId);
            request.setMethod('GET');

            try {
                HttpResponse response = http.send(request);

                Case supportCase = [
                    SELECT Id, Description
                    FROM Case
                    WHERE Id = :req.caseId
                    LIMIT 1
                ];

                supportCase.Description =
                    supportCase.Description +
                    '\n\nCustomer API Response:\n' +
                    response.getBody();

                update supportCase;

                API_Integration_Log__c log = new API_Integration_Log__c();
                log.Case__c = req.caseId;
                log.Request_URL__c =
                    'https://jsonplaceholder.typicode.com/users/' + req.customerId;
                log.Response_Status__c = response.getStatusCode();
                log.Response_Body__c = response.getBody();
                log.Integration_Status__c = 'Success';

                insert log;

            } catch (Exception ex) {

                API_Integration_Log__c log = new API_Integration_Log__c();
                log.Case__c = req.caseId;
                log.Integration_Status__c = 'Failed';
                log.Error_Message__c = ex.getMessage();

                insert log;
            }
        }
    }
}