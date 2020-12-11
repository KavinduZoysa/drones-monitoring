import ballerina/io;
public function populateTables() returns boolean {
    return createTables();
}

public function signUp(json info) returns boolean {
    return addDroneUser(info, info.droneID.toString(), info.firstName.toString(), info.lastName.toString(), info.password.toString());
}

public function getLoginInfo(json droneUserInfo) returns json {
    json? userInfo = getDroneUserInfo(droneUserInfo.droneID.toString(), droneUserInfo.password.toString());

    io:println(userInfo);
    json responseJson = {};
    if (userInfo is ()) {
        responseJson = {
            "success" : false
        };
    } else {
        responseJson = {
            "success" : true,
            "result" : userInfo
        };  
    }
    
    return responseJson;
}

public function setInfo(json droneInfo) returns boolean {
    return updateDroneInfo(droneInfo.droneID.toString(), droneInfo.latitude.toString(), droneInfo.longitude.toString());
}

public function getDronesInfo(string droneID) returns @tainted json|error {
    return selectDronesInfo(droneID);
}

public function getDroneLocation() returns json[] {
    return selectDroneLocation();
}

public function getRestrictedAreas() returns json[] {
    return selectRestrictedAreas();
}

public function setRestrictedArea(json polygon) returns boolean {
    json[] points = <json[]> checkpanic polygon.points;
    return insertRestrictedArea(polygon.areaId.toString(), points.length(), polygon.name.toString(), (checkpanic polygon.points).toJsonString());
}
