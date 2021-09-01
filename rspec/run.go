package rspec

import (
	"fmt"
	"gospec/variables"
	"os"
	"os/exec"
	"strconv"
)

// RunSpecSubprocess intakes a group of specs as a string and runs them in a test environment
// using the databaseNumber provided
func RunSpecSubprocess(specs []string, databaseNumber int) []byte {
	args := []string{"exec", "rspec"}
	fmt.Println(specs)
	args = append(append(args, specs...), "-f", "j", "--no-profile")
	fmt.Println(args)
	cmd := exec.Command("bundle", args...)
	cmd.Env = append(os.Environ(), "DATABASE_NUMBER="+strconv.Itoa(databaseNumber))
	out, _ := cmd.Output()
	fmt.Println(variables.Green, "group:", databaseNumber, "complete")
	return out
}
