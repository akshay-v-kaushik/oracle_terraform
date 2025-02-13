#!/usr/bin/env python3
import sys
import cx_Oracle

def usage():
    print("Usage: {} <endpoint> <port> <master_username> <master_password> <db_name> <read_username> <read_user_password> <rw_username> <rw_user_password> <environment>".format(sys.argv[0]))
    sys.exit(1)

def main():
    if len(sys.argv) != 11:
        usage()

    endpoint           = sys.argv[1]
    port               = sys.argv[2]
    master_username    = sys.argv[3]
    master_password    = sys.argv[4]
    db_name            = sys.argv[5]
    read_username      = sys.argv[6]
    read_user_password = sys.argv[7]
    rw_username        = sys.argv[8]
    rw_user_password   = sys.argv[9]
    environment        = sys.argv[10]  # Can be used for logging or conditional logic if needed

    # Build the DSN for Oracle. For an Oracle RDS instance, the service name is typically your db_name.
    dsn = cx_Oracle.makedsn(endpoint, port, service_name=db_name)

    try:
        connection = cx_Oracle.connect(master_username, master_password, dsn)
    except cx_Oracle.DatabaseError as err:
        print("Error connecting to Oracle: {}".format(err))
        sys.exit(1)

    cursor = connection.cursor()

    def create_user(username, password, grants):
        try:
            # Check if the user already exists (Oracle stores usernames in uppercase)
            cursor.execute("SELECT COUNT(*) FROM dba_users WHERE username = :uname", uname=username.upper())
            count = cursor.fetchone()[0]
            if count == 0:
                print("Creating user {} ...".format(username))
                cursor.execute("CREATE USER {} IDENTIFIED BY \"{}\"".format(username, password))
                # Execute each grant statement
                for grant_stmt in grants:
                    cursor.execute(grant_stmt.format(username=username))
                print("User {} created successfully.".format(username))
            else:
                print("User {} already exists.".format(username))
        except cx_Oracle.DatabaseError as err:
            print("Error creating user {}: {}".format(username, err))

    # Define grants for the read-only user and the read-write user.
    read_grants = [
        "GRANT CONNECT TO {username}",
        "GRANT SELECT ANY TABLE TO {username}"
    ]
    rw_grants = [
        "GRANT CONNECT TO {username}",
        "GRANT RESOURCE TO {username}"
    ]

    # Create the users using the provided usernames and passwords.
    create_user(read_username, read_user_password, read_grants)
    create_user(rw_username, rw_user_password, rw_grants)

    connection.commit()
    cursor.close()
    connection.close()

if __name__ == "__main__":
    main()
