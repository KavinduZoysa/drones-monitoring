import ballerinax/mysql;
import ballerina/sql;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerina/lang.'float as floats;

string dbUser = "root";
string dbPassword = "root";
string db = "drones_monitor";
mysql:Client mysqlClient = initializeClients();
float[][][] restrictedAreas = readRestrictedAreas();

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

function readRestrictedAreas() returns float[][][] {
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_RESTRICTED_AREAS);

    float[][][] res = [];
    int i = 0;
    error? e = resultStream.forEach(function(record {} result) {
        json[] points = <json[]> checkpanic result["points"].toString().fromJsonFloatString();
        float[][] p = [];
        int j = 0;
        foreach json point in points {
            p[j] = [<float> point.longitude, <float> point.latitude];
            j = j + 1;
        }
        res[i] = p;
        i = i + 1;
    });
    log:printInfo(res.toString());
    return res;
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

public function addDroneUser(json info, string firstName, string lastName, string username, string password, string role) returns boolean {
    sql:ParameterizedQuery ADD_DRONES_USER = `INSERT INTO users_info(firstName, lastName, username, password, role) values (${firstName}, ${lastName}, ${username}, ${password}, ${role})`;
    sql:ExecutionResult|sql:Error result = mysqlClient->execute(ADD_DRONES_USER);
    if (result is sql:Error) {
        return false;
    }

    log:printInfo(io:sprintf("Added user %s successfully.", username));
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

public function getDroneUserInfo(string username, string password) returns @tainted json|boolean {
    sql:ParameterizedQuery SELECT_DRONE_USER_INFO = `SELECT firstName, lastName, id, username, role FROM users_info WHERE username = ${username} AND password = ${password}`;
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_DRONE_USER_INFO);

    record {|record {} value;|}|error? result = resultStream.next();
    checkpanic resultStream.close();
    if (result is record {|record {} value;|}) {
        record {} r = result.value;
        json j = {
            firstName : r["firstName"].toString(),
            lastName : r["lastName"].toString(),
            userID : r["id"].toString(),
            username : r["username"].toString(),
            role : r["role"].toString()
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
    checkpanic resultStream.close();
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

public function selectDroneLocation() returns @untainted json[] {
    time:Time time = time:currentTime();
    int t = time.time/1000;
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_DRONES_INFO);

    json[] res = []; 
    int i = 0;

    while(true) {
        var result = resultStream.next();
        if (result == ()) {
            break;
        }
        if (result is error) {
            continue;
        }

        record{} val = <record {}> result;
        record{} droneLocation = <record {}> val["value"];
        float|error tempLat = floats:fromString(droneLocation["latitude"].toString());
        float|error tempLong = floats:fromString(droneLocation["longitude"].toString());
        if (tempLat is error || tempLong is error) {
            log:printError("Invalid latitude and longitute at " + droneLocation["timestamp"].toString());
            continue;
        } 
        float lat = <float> tempLat;
        float long = <float> tempLong;

        boolean isInRestrictedArea = false;
        foreach float[][] area in restrictedAreas {
            if (isInsidePolygon(area, [long, lat])) {
                isInRestrictedArea = true;
                break;
            }
        }
        if (t - <int> droneLocation["timestamp"] > 20) {
            continue;
        }

        json j = {
            droneID : droneLocation["droneID"].toString(),
            latitude : lat.toString(),
            longitude : long.toString(),
            isRestricted : isInRestrictedArea
        };
        res[i] = j;
        i = i + 1;
    }

    checkpanic resultStream.close();
    return res;
}

public function selectAllDroneLocation() returns json[] {
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_DRONES_INFO);

    json[] res = []; 
    int i = 0;
    error? e = resultStream.forEach(function(record {} result) {
        float|error lat = floats:fromString(result["latitude"].toString());
        float|error long = floats:fromString(result["longitude"].toString());
        if (lat is error || long is error) {
            log:printError("Invalid latitude and longitute at " + result["timestamp"].toString());
        } else {
            boolean isInRestrictedArea = false;
            foreach float[][] area in restrictedAreas {
                if (isInsidePolygon(area, [long, lat])) {
                    isInRestrictedArea = true;
                    break;
                }
            }

            json j = {
                droneID : result["droneID"].toString(),
                latitude : lat.toString(),
                longitude : long.toString(),
                isRestricted : isInRestrictedArea
            };
            res[i] = j;
            i = i + 1;
        }
    });
    checkpanic resultStream.close();
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

public function selectRestrictedAreas() returns json[] {
    stream<record{}, error> resultStream = mysqlClient->query(SELECT_RESTRICTED_AREAS);

    json[] res = [];
    int i = 0;
    error? e = resultStream.forEach(function(record {} result) {
        res[i] = {
            ID : <int> result["areaId"],
            name : result["name"].toString(),
            points : checkpanic result["points"].toString().fromJsonFloatString()
        };
        i = i + 1;
    });
    checkpanic resultStream.close();
    return res;
}

public function insertRestrictedArea(int numOfPoints, string name, string points) returns boolean {
    sql:ParameterizedQuery ADD_DRONE_INFO = `INSERT INTO restricted_areas(name, numberOfPoints, points) values (${name}, ${numOfPoints}, ${points})`;
    io:println(points);
    sql:ExecutionResult|sql:Error result = mysqlClient->execute(ADD_DRONE_INFO);
    if (result is sql:Error) {
        io:println(result);
        return false;
    }

    log:printInfo(io:sprintf("updated restricted area info %s, %s successfully.", name, points));
    restrictedAreas = readRestrictedAreas();
    return true;
}

public function reomveRestrictedArea(int id) returns boolean {
    sql:ParameterizedQuery DELETE_RETRICTED_AREA = `DELETE FROM restricted_areas WHERE areaId = ${id}`;
    sql:ExecutionResult|sql:Error result = mysqlClient->execute(DELETE_RETRICTED_AREA);
    if (result is sql:Error) {
        io:println(result);
        return false;
    }

    log:printInfo(io:sprintf("deleted restricted area %s successfully.", id));
    restrictedAreas = readRestrictedAreas();
    return true;
}