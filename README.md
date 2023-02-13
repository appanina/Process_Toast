# AWSLabs
## Description
This repo contains demonstration scripts that I used for various purposes such as blogs, articles etc.. and should be useful for validating. 

# Topics
## PostgreSQL
### PROCESS_TOAST
Starting PostgreSQL 14, you have the option to exclude a TOAST when manually vacuumed. This is extremely useful in scenarios where the level of bloat or transaction age of the main and toast relations differs a lot.

For instance, if the toast is heavily bloated and age of the main table is at near danger for wraparound but the age of toast is not a danger for wraparound, manually vacuuming just the main relation is a lot helpful, this helps in two ways: 1. saves time and 2. avoids a wraparound quickly. The TOAST can be manually vacuumed at a later time to remove the bloat. This is also true for other way around that you can simply a manual VACUUM on the TOAST relation to get out of danger. Another example would be to remove the bloat quickly from the main relation to improve the efficiency of indexes that otherwise do not rely on TOAST’s data.

This script is used to demonstrate the difference in execution times of vaccuming with and without TOAST

**To run the script:**
```
nohup ./Process_Toast.sh <end_point OR IP address> <port> <database> <user> <password> &
```
**For example:**
```
nohup ./Process_Toast.sh database-1.xxxxxxxxxxxx.us-west-2-elephant.rds.amazonaws.com 5432 postgres postgres Oracle123 &
```
