package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strconv"
)

// performAllDatabaseAction creates a set of 10 databases 0 - 9
// to handle the max number of concurrent processes that can occur
func performAllDatabaseAction(action string) {
	for i := 0; i < 9; i++ {
		dataBaseAction(action, i)
	}
}

// dataBaseAction performs a rails database action (create/migrate)
//for given database number (0 - 9)
func dataBaseAction(action string, databaseNumber int) {
	if action != "create" && action != "migrate" {
		log.Fatalln("valid database actions are 'create', or 'migrate'")
	}
	cmd := exec.Command("bin/rake", "db:"+action)
	cmd.Env = append(os.Environ(), "RAILS_ENV=test", "DATABASE_NUMBER="+strconv.Itoa(databaseNumber))
	out, err := cmd.Output()
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println("database: "+strconv.Itoa(databaseNumber), string(out))
}
