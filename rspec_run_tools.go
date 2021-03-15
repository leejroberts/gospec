package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

// runSpecSubprocess intakes a group of specs as a string and runs them in a test environment
// using the databaseNumber provided
func runSpecSubprocess(specs string, databaseNumber int) []byte {
	args := []string{"exec", "rspec"}
	args = append(append(args, strings.Split(specs, " ")...), "-f", "j") // TODO: don't join specs to string
	cmd := exec.Command("bundle", args...)
	cmd.Env = append(os.Environ(), "DATABASE_NUMBER="+strconv.Itoa(databaseNumber))
	out, _ := cmd.Output()
	fmt.Println("group:", databaseNumber, "complete")
	return out
}
