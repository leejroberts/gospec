package main

import (
	"fmt"
	"os"
	"sync"
	"time"
)

func main() {
	start := time.Now()
	rSpecr := RSpecr{files: os.Args[1:], maxSplit: 10, splitMethod: "rotating", result: &Result{}}
	rSpecr.run()
	finish := time.Now()
	timeElapsed := finish.Sub(start)
	rSpecr.logResults(timeElapsed)
}

func (r RSpecr)logResults(timeElapsed time.Duration) {
	r.result.logFailures()
	fmt.Println()
	fmt.Println(White, "Finished in", timeElapsed)
	r.result.logSummary()
	r.result.logFailureSummary()
}

// TODO: add config file to allow setting the number of processes
type RSpecr struct {
	files       []string
	maxSplit    int    // TODO: determine how/when to change number
	splitMethod string // TODO: determine when to change method
	result      *Result
}

// run runs the specs for all files/specs passed in as arguments from the command line
func (r RSpecr) run() {
	var c = make(chan Result)
	var wg sync.WaitGroup

	for i, specs := range r.splitSpecs() {
		wg.Add(1)

		go func(specGroup string, databaseNumber int) {
			defer wg.Done()
			jsonOutput := runSpecSubprocess(specGroup, databaseNumber)
			c <- jsonToResult(jsonOutput)
		}(specs, i)
	}
	go func() {
		wg.Wait()
		close(c)
	}()

	for groupResult := range c {
		r.result.merge(groupResult)
	}
}

// TODO: add splitting all spec files found when no argument is given
// TODO: add using a search string
// TODO: verify that special spec it statements are covered in addition to the standard it statements
// splitSpecs splits the specs for a single file into groups less than or equal to maxSplit
// It returns a slice of strings in the following format
// ":3:22:45:77:89" / each number indicates the position of an it statement
func (r RSpecr) splitSpecs() []string {
	if r.splitMethod == "sequential" {
		return splitSpecsSequential(r.files, r.maxSplit) // TODO: do I need this?
	} else {
		return splitSpecsRotating(r.files, r.maxSplit)
	}
}
