const ERROR_INVALID_FORMAT = "Invalid format in request body";
const FAILED = "failed: ";

const CREATE_USER_INFO_TABLE = "CREATE TABLE IF NOT EXISTS users_info(id int NOT NULL AUTO_INCREMENT PRIMARY KEY, droneID VARCHAR(255) UNIQUE, firstName VARCHAR(255), lastName VARCHAR(255), password VARCHAR(255));";
const string CREATE_RAW_DATA_TABLE = "CREATE TABLE IF NOT EXISTS raw_data(rawData VARCHAR(255));";
const CREATE_DRONE_INFO_TABLE = "CREATE TABLE IF NOT EXISTS drones_info(droneID VARCHAR(255), latitude VARCHAR(255), longitude VARCHAR(255), time VARCHAR(255));";
