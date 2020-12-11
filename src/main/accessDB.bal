import ballerinax/mysql;
import ballerina/sql;
import ballerina/io;
import ballerina/log;

string dbUser = "root";
string dbPassword = "root";
string db = "drones_monitor";
mysql:Client mysqlClient = initializeClients();

function initializeClients() returns mysql:Client {
    mysql:Client|sql:Error tempClient = new ("localhost", dbUser, dbPassword, db);
    if (tempClient is sql:Error) {
        io:println("Error when initializing the MySQL client ", tempClient);
    } else {
        io:println("Simple MySQL client created successfully");
        // check tempClient.close();
    }
    return <mysql:Client>tempClient;
}

public function createTables() returns boolean {
    sql:ExecutionResult|sql:Error result = mysqlClient->execute(CREATE_USER_INFO_TABLE);
    if (result is sql:Error) {
        return false;
    }
    log:printInfo("Creates user_info table");

    result = mysqlClient->execute(CREATE_RAW_DATA_TABLE);
    if (result is sql:Error) {
        return false;
    }
    log:printInfo("Create raw_data table");

    result = mysqlClient->execute(CREATE_DRONE_INFO_TABLE);
    if (result is sql:Error) {
        return false;
    }
    log:printInfo("Create drone_info table");

    result = mysqlClient->execute(CREATE_RESTRICTED_AREA_INFO_TABLE);
    if (result is sql:Error) {
        return false;
    }
    log:printInfo("Create restricted_area table");

    return true;
}

public function addDroneUser(json info, string droneID, string firstName, string lastName, string password) returns boolean {
    sql:ParameterizedQuery ADD_DRONES_USER = `INSERT INTO users_info(droneID, firstName, lastName, password) values (${droneID}, ${firstName}, ${lastName}, ${password})`;
    sql:ExecutionResult|sql:Error result = mysqlClient->execute(ADD_DRONES_USER);
    if (result is sql:Error) {
        return false;
    }

    log:printInfo(io:sprintf("Added user %s successfully.", droneID));
    return true;
}

public function addAsRawData(string rawData) returns boolean {
    sql:ParameterizedQuery ADD_RAW_DATA = `INSERT INTO raw_data(rawData) values (${rawData})`;
    sql:ExecutionResult|sql:Error result = mysqlClient->execute(ADD_RAW_DATA);
    if (result is sql:Error) {
        return false;
    }

    return true;
}

type LoginInfo record {|
    string droneID;
    string firstName;
    string lastName;
    string userID;
|};

public function getDroneUserInfo(string droneID, string password) returns @tainted json|boolean {
    sql:ParameterizedQuery SELECT_DRONE_USER_INFO = `SELECT droneID, firstName, lastName, id as userID FROM users_info WHERE droneID = ${droneID} AND password = ${password}`;
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_DRONE_USER_INFO);

    record {|record {} value;|}|error? result = resultStream.next();
    if (result is record {|record {} value;|}) {
        record {} r = result.value;
        json j = {
            droneID : r["droneID"].toString(),
            firstName : r["firstName"].toString(),
            lastName : r["lastName"].toString(),
            userID : r["userID"].toString()
        };
        return j;
    } else if (result is error) {
        return false;
    } 
}

public function selectDronesInfo(string droneID) returns @tainted json|error {
    sql:ParameterizedQuery SELECT_DRONES_INFO = `SELECT count(*) as count from drones_monitor.drones_info where droneID = ${droneID}`;
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_DRONES_INFO);

    record {|record {} value;|}|error? result = resultStream.next();
    if (result is record {|record {} value;|}) {
        return {
            droneID : droneID,
            count : result.value["count"].toString()
        };
    } else if (result is ()) {
        return {
            droneID : droneID,
            count : ""
        };
    }
    return <error>result;
}

public function selectDroneLocation() returns json[] {
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_DRONES_INFO);

    json[] res = []; 
    int i = 0;
    error? e = resultStream.forEach(function(record {} result) {
        json j = {
            droneID : result["droneID"].toString(),
            latitude : result["latitude"].toString(),
            longitude : result["longitude"].toString()
        };
        res[i] = j;
        i = i + 1;
    });
    return res;
}

public function updateDroneInfo(string droneId, string latitude, string longitude) returns boolean {
    sql:ParameterizedQuery ADD_DRONE_INFO = `INSERT INTO drones_info(droneID, latitude, longitude, timestamp) values (${droneId}, ${latitude}, ${longitude}, UNIX_TIMESTAMP(now()))`;
    sql:ExecutionResult|sql:Error result = mysqlClient->execute(ADD_DRONE_INFO);
    if (result is sql:Error) {
        io:println(result);
        return false;
    }

    log:printInfo(io:sprintf("updated drone info %s, %s, %s successfully.", droneId, latitude, longitude));
    return true;
}

public function addRestrictedArea(string name, int numOfPoints, string points) {
    
}

public function selectRestrictedAreas() returns json[] {
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_RESTRICTED_AREAS);

    json[] res = [];
    int i = 0;
    error? e = resultStream.forEach(function(record {} result) {
        res[i] = checkpanic result["points"].toString().fromJsonFloatString();
        i = i + 1;
    });
    return res;
}

public function insertRestrictedArea(string areaId, int numOfPoints, string name, string points) returns boolean {
    sql:ParameterizedQuery ADD_DRONE_INFO = `INSERT INTO restricted_areas(areaId, name, numberOfPoints, points) values (${areaId}, ${name}, ${numOfPoints}, ${points})`;
    sql:ExecutionResult|sql:Error result = mysqlClient->execute(ADD_DRONE_INFO);
    if (result is sql:Error) {
        io:println(result);
        return false;
    }

    log:printInfo(io:sprintf("updated restricted area info %s, %s, %s successfully.", areaId, name, points));
    return true;
}