const ERROR_INVALID_FORMAT = "Invalid format in request body";
const FAILED = "failed: ";

const CREATE_USER_INFO_TABLE = "CREATE TABLE IF NOT EXISTS drones_monitor.drones_info(droneID VARCHAR(255), latitude VARCHAR(255), longitude VARCHAR(255), timestamp int(15));";
const string CREATE_RAW_DATA_TABLE = "CREATE TABLE IF NOT EXISTS raw_data(rawData VARCHAR(255));";
const CREATE_DRONE_INFO_TABLE = "CREATE TABLE IF NOT EXISTS drones_info(droneID VARCHAR(255), latitude VARCHAR(255), longitude VARCHAR(255), time VARCHAR(255));";
const SELECT_DRONES_INFO_PER_DRONE = "INSERT INTO drones_info(droneID, latitude, longitude, time) values (${droneId}, ${latitude}, ${longitude}, ${t.time.toString()})";
const SELECT_DRONES_INFO = "SELECT * FROM drones_monitor.drones_info WHERE timestamp IN (SELECT MAX(timestamp) FROM drones_monitor.drones_info GROUP BY droneID);";
const CREATE_RESTRICTED_AREA_INFO_TABLE = "CREATE TABLE IF NOT EXISTS restricted_areas(areaId INT(10), name VARCHAR(255), numberOfPoints INT(10), points VARCHAR(255), PRIMARY KEY (areaId));";
const SELECT_RESTRICTED_AREAS = "SELECT * FROM drones_monitor.restricted_areas;";
