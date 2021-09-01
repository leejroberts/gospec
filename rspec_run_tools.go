package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
)

// runSpecSubprocess intakes a group of specs as a string and runs them in a test environment
// using the databaseNumber provided
func runSpecSubprocess(specs []string, databaseNumber int) []byte {
	args := []string{"exec", "rspec"}
	fmt.Println(specs)
	args = append(append(args, specs...), "-f", "j", "--no-profile")
	fmt.Println(args)
	cmd := exec.Command("bundle", args...)
	cmd.Env = append(os.Environ(), "DATABASE_NUMBER="+strconv.Itoa(databaseNumber))
	out, _ := cmd.Output()
	fmt.Println(Green, "group:", databaseNumber, "complete")
	return out
}
