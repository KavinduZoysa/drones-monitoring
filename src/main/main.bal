import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/config;

http:ListenerConfiguration helloWorldEPConfig = {
    secureSocket: {
         keyFile: config:getAsString("key.file"),
         certFile: config:getAsString("cert.file")
    }
};

listener http:Listener helloWorldEP = new (9090, config = helloWorldEPConfig);

@http:ServiceConfig {
    basePath: "/drones-monitor",
    cors: {
        allowOrigins: ["*"]
    }
}
service dronesMonitor on helloWorldEP {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/health-check"
    }
    resource function healthCheck(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {
            "server": true
        };
        res.setJsonPayload(<@untainted>responseJson);
        respondClient(caller, res);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/populate-tables"
    }
    resource function populateTables(http:Caller caller, http:Request req) {
        http:Response res = new;
        if (!populateTables()) {
            res.statusCode = 500;
            res.setPayload("Cannot create tables");
        }
        respondClient(caller, res);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/signup"
    }
    resource function signUp(http:Caller caller, http:Request req) {
        http:Response res = new;

        var payload = req.getJsonPayload();
        if (payload is json) {
            json responseJson = {
                "success" : signUp(<@untainted>payload)
            };
            res.setJsonPayload(<@untainted>responseJson);
        } else {
            res.statusCode = 500;
            res.setPayload("Cannot signup");
            log:printError(ERROR_INVALID_FORMAT);
        }
        respondClient(caller, res);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/login"
    }
    resource function logIn(http:Caller caller, http:Request req) {
        http:Response res = new;

        var payload = req.getJsonPayload();
        if (payload is json) {            
            res.setJsonPayload(<@untainted>getLoginInfo(<@untainted>payload));
        } else {
            res.statusCode = 500;
            log:printError(ERROR_INVALID_FORMAT);
        }
        respondClient(caller, res);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/drone-info"
    }
    resource function setDroneInfo(http:Caller caller, http:Request req) {
        http:Response res = new;

        var payload = req.getJsonPayload();
        if (payload is json) {            
            res.setJsonPayload(<@untainted>setInfo(<@untainted>payload));
        } else {
            res.statusCode = 500;
            log:printError(ERROR_INVALID_FORMAT);
        }
        respondClient(caller, res);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/get-drone-info/{droneID}"
    }
    resource function getDronesInfo(http:Caller caller, http:Request req, string droneID) {
        http:Response res = new; 
        json|error info = <@untainted>getDronesInfo(<@untainted>droneID);

        if (info is json) {
            res.setJsonPayload(info);
        } else {
            res.statusCode = 500;
            log:printError(ERROR_INVALID_FORMAT);   
        }         
        respondClient(caller, res);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/get-drone-location"
    }
    resource function getDroneLocation(http:Caller caller, http:Request req) {
        http:Response res = new;           
        res.setJsonPayload(<@untainted>getDroneLocation());
        respondClient(caller, res);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/get-restricted-areas"
    }
    resource function getRestrictedAreas(http:Caller caller, http:Request req) {
        http:Response res = new;           
        res.setJsonPayload(<@untainted>getRestrictedAreas());
        respondClient(caller, res);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/add-restricted-area"
    }
    resource function addRestrictedAreas(http:Caller caller, http:Request req) {
        http:Response res = new;

        var payload = req.getJsonPayload();
        if (payload is json) {            
            res.setJsonPayload(<@untainted>setRestrictedArea(<@untainted>payload));
        } else {
            res.statusCode = 500;
            log:printError(ERROR_INVALID_FORMAT);
        }
        respondClient(caller, res);
    }
}

public function respondClient(http:Caller caller, http:Response res) {
    var result = caller->respond(res);
    if (result is error) {
        io:print(result);
    }       
}