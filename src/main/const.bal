const ERROR_INVALID_FORMAT = "Invalid format in request body";
const FAILED = "failed: ";

const CREATE_USER_INFO_TABLE = "CREATE TABLE IF NOT EXISTS drones_monitor.users_info(id INT NOT NULL AUTO_INCREMENT, firstName VARCHAR(255), lastName VARCHAR(255), username VARCHAR(255) UNIQUE, password VARCHAR(255), role VARCHAR(255), PRIMARY KEY (id));";
const CREATE_RAW_DATA_TABLE = "CREATE TABLE IF NOT EXISTS drones_monitor.raw_data(rawData VARCHAR(255));";
const CREATE_DRONE_INFO_TABLE = "CREATE TABLE IF NOT EXISTS drones_monitor.drones_info(droneID VARCHAR(255), latitude VARCHAR(255), longitude VARCHAR(255), timestamp int(15));";
const CREATE_RESTRICTED_AREA_INFO_TABLE = "CREATE TABLE IF NOT EXISTS drones_monitor.restricted_areas(areaId INT(50) NOT NULL AUTO_INCREMENT, name VARCHAR(255), numberOfPoints INT(50), points VARCHAR(2550), PRIMARY KEY (areaId));";

const SELECT_DRONES_INFO = "SELECT * FROM drones_monitor.drones_info WHERE timestamp IN (SELECT MAX(timestamp) FROM drones_monitor.drones_info GROUP BY droneID);";
const SELECT_RESTRICTED_AREAS = "SELECT * FROM drones_monitor.restricted_areas;";
