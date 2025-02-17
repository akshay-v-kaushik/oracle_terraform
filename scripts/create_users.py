#!/usr/bin/env python3
import sys
import cx_Oracle

def usage():
    print("Usage: {} <endpoint> <port> <master_username> <master_password> <db_name> <admin_username> <admin_password> <read_username> <read_user_password> <rw_username> <rw_user_password> <environment>".format(sys.argv[0]))
    sys.exit(1)

def main():
    if len(sys.argv) != 13:
        usage()

    endpoint           = sys.argv[1]
    port               = sys.argv[2]
    master_username    = sys.argv[3]
    master_password    = sys.argv[4]
    db_name            = sys.argv[5]
    admin_username     = sys.argv[6]
    admin_password     = sys.argv[7]
    read_username      = sys.argv[8]
    read_user_password = sys.argv[9]
    rw_username        = sys.argv[10]
    rw_user_password   = sys.argv[11]
    environment        = sys.argv[12]  

    dsn = cx_Oracle.makedsn(endpoint, port, service_name=db_name)

    try:
        connection = cx_Oracle.connect(master_username, master_password, dsn)
    except cx_Oracle.DatabaseError as err:
        print("Error connecting to Oracle: {}".format(err))
        sys.exit(1)

    cursor = connection.cursor()

    def create_user(username, password, grants):
        try:
            cursor.execute("SELECT COUNT(*) FROM dba_users WHERE username = :uname", uname=username.upper())
            count = cursor.fetchone()[0]
            if count == 0:
                print("Creating user {} ...".format(username))
                cursor.execute("CREATE USER {} IDENTIFIED BY \"{}\"".format(username, password))
                for grant_stmt in grants:
                    cursor.execute(grant_stmt.format(username=username))
                print("User {} created successfully.".format(username))
            else:
                print("User {} already exists.".format(username))
        except cx_Oracle.DatabaseError as err:
            print("Error creating user {}: {}".format(username, err))

    admin_grants = [
        "GRANT DBA TO {username}"
    ]
    read_grants = [
        "GRANT CONNECT TO {username}",
        "GRANT SELECT ANY TABLE TO {username}"
    ]
    rw_grants = [
        "GRANT CONNECT TO {username}",
        "GRANT RESOURCE TO {username}"
    ]

    create_user(admin_username, admin_password, admin_grants)
    create_user(read_username, read_user_password, read_grants)
    create_user(rw_username, rw_user_password, rw_grants)

    connection.commit()
    cursor.close()
    connection.close()

if __name__ == "__main__":
    main()
