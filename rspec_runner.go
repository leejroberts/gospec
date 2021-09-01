package main

import (
	"fmt"
	"sync"
	"time"
)

// RSpecRunner splits the specs into groups to run concurrently
// merging the results for review
type RSpecRunner struct {
	files       []string
	maxSplit    int    // currently defaults to 10
	splitMethod string // currently only option is 'rotating'
	startTime   time.Time
	endTime     time.Time
	result      *Result
}

func initRspecRunner(files []string) RSpecRunner {
	return RSpecRunner{files: files, maxSplit: 10, splitMethod: "rotating", result: &Result{}}
}

// run runs the specs for all files/specs passed in as arguments from the command line
func (r RSpecRunner) run() {
	var c = make(chan Result)
	var wg sync.WaitGroup

	for i, specs := range splitSpecsRotating(r.files, r.maxSplit) {
		wg.Add(1)

		go func(specGroup []string, databaseNumber int) {
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

func (r RSpecRunner) logResults() {
	r.result.logFailures()
	fmt.Println() // spacer for visual clarity
	r.printTimeElapsed()
	r.result.logSummary()
	r.result.logFailureSummary()
}

func (r RSpecRunner) printTimeElapsed() {
	fmt.Println(White, "Finished in", r.endTime.Sub(r.startTime))
}
