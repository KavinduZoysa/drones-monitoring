import ballerina/io;
public function populateTables() returns boolean {
    return createTables();
}

public function signUp(json info) returns boolean {
    return addDroneUser(info, info.firstName.toString(), info.lastName.toString(), info.username.toString(), info.password.toString(), info.role.toString());
}

public function getLoginInfo(json droneUserInfo) returns json {
    json? userInfo = getDroneUserInfo(droneUserInfo.username.toString(), droneUserInfo.password.toString());

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

public function deleteRestrictedArea(json areaInfo) returns boolean {
    return reomveRestrictedArea(<int> areaInfo.ID);
}

public function setRestrictedArea(json polygon) returns boolean {
    json[] points = <json[]> checkpanic polygon.points;
    return insertRestrictedArea(points.length(), polygon.name.toString(), (checkpanic polygon.points).toJsonString());
}

function isInsidePolygon(float[][] polygon, float[] position) returns boolean {
    float lat = position[0];
    float lng = position[1];

    int l = polygon.length();
    int j = l - 1;
    boolean inside = checkPoints(polygon[0], polygon[j], position, false);
    foreach var i in 0..<l-1 {
        j = i + 1;
        inside = checkPoints(polygon[i], polygon[j], position, inside);
    } 
    return inside;    
}

function checkPoints(float[] pointA, float[] pointB, float[] position, boolean inside) returns boolean {
    float latA = pointA[1];
    float lngA = pointA[0];

    float latB = pointB[1];
    float lngB = pointB[0];

    float latP = position[1];
    float lngP = position[0];   
    // y -> lat
    // x -> lng 

    boolean intersect = ((lngA > lngP) != (lngB > lngP)) && (latP < (latA - latB) * (lngP - lngB)/(lngA - lngB) + latB);
    if (intersect) {
        return !inside;
    }
    return inside;
}
