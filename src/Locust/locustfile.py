from locust import HttpUser, task, between

class QuickstartUser(HttpUser):
    wait_time = between(1, 2)

    def on_start(self):
        self.client.post("/create-ticket", json={
        "amount": 40000,
        "creationTimestamp": "2024-07-09 13:39:31.235070",
        "id": 1,
        "receiverAccount": "112110211",
        "receiverBank": "TestBank2",
        "receiverName": "Sample Nmae",
        "senderAccount": "1101121",
        "senderBank": "Sample Bank",
        "senderName": "John Doe"
         })
        
        self.client.post("/create-revenue-item", json={
        "Action": "Add",
        "Attribute": "RevenueCode",
        "ExtSiteID": "CA",
        "Data": {
        "gc_revenue_code_id": 2,
        "source_id": 12,
        "RevenueCodeID":"13bc29b3-e2da-4007-95db-106423967dd0",
        "ExtRevenueCodeID":"MARQRT@",
        "RevenueCodeName": "David TEST 2",
        "Priority":1,
        "DrawDownAmount":0,
        "RCValue1": None,
        "RCValue2":None,
        "RCValue3":None,
        "RCValue4":None,
        "PropData": None,
        "IsCalcDrawDown": False
    }
    })
        

    @task
    def hello_world(self):
        self.client.get("/get-tickets")
        self.client.get("/get-revenue-item")


