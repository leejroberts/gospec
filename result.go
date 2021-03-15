package main

import (
	"encoding/json"
	"fmt"
	"log"
	"strconv"
)

// Result can either be the result of a group of specs or the merged result of all specs
type Result struct {
	Version     string    `json:"version"`
	Messages    []string  `json:"messages"`
	Seed        int       `json:"seed"`
	Examples    []Example `json:"examples"`
	Summary     Summary   `json:"summary"`
	SummaryLine string    `json:"summary_line"`
}
type Example struct {
	ID              string      `json:"id"`
	Description     string      `json:"description"`
	FullDescription string      `json:"full_description"`
	Status          string      `json:"status"`
	FilePath        string      `json:"file_path"`
	LineNumber      int         `json:"line_number"`
	RunTime         float64     `json:"run_time"`
	PendingMessage  interface{} `json:"pending_message"`
	Exception       Exception   `json:"exception,omitempty"`
}
type Exception struct {
	Class     string   `json:"class"`
	Message   string   `json:"message"`
	Backtrace []string `json:"backtrace"`
}
type Summary struct {
	Duration                     float64 `json:"duration"`
	ExampleCount                 int     `json:"example_count"`
	FailureCount                 int     `json:"failure_count"`
	PendingCount                 int     `json:"pending_count"`
	ErrorsOutsideOfExamplesCount int     `json:"errors_outside_of_examples_count"`
}

// merge merges the data from another result into the current result
func (r *Result) merge(otherResult Result) {
	r.Examples = append(r.Examples, otherResult.Examples...)
	r.Summary.Duration += otherResult.Summary.Duration
	r.Summary.ErrorsOutsideOfExamplesCount += otherResult.Summary.ErrorsOutsideOfExamplesCount
	r.Summary.ExampleCount += otherResult.Summary.ExampleCount
	r.Summary.PendingCount += otherResult.Summary.PendingCount
	r.Summary.FailureCount += otherResult.Summary.FailureCount
}

func (r Result) log() {
	r.logFailures()
	r.logSummary()
}

func (r Result) logFailures() {
	failureCount := 0
	for _, example := range r.Examples {
		if example.Status == "failed" {
			failureCount++
			logFailedExample(failureCount, example)
		}
	}
}

func logFailedExample(failureCount int, example Example) {
	fmt.Println()
	fmt.Println(White, strconv.Itoa(failureCount)+")", example.FullDescription)
	fmt.Println("\t" + Red + example.Status)
	fmt.Println("\t" + Red + example.Exception.Message)
	fmt.Println(Cyan + example.FilePath + ":" + strconv.Itoa(example.LineNumber))
}

func (r Result) logSummary() {
	fmt.Println(r.summaryTextColor(),
		r.Summary.ExampleCount,
		"examples,",
		r.Summary.FailureCount,
		"failures",
		r.Summary.PendingCount,
		"pending",
		r.Summary.ErrorsOutsideOfExamplesCount,
		"errors outside of examples",
	)
}

func (r Result) logFailureSummary() {
	headerPrinted := false
	for _, example := range r.Examples {
		if example.Status == "failed" {
			if headerPrinted == false {
				fmt.Println(White, "Failed Examples")
				headerPrinted = true
			}
			logFailedExampleSummary(example)
		}
	}
}

func logFailedExampleSummary(example Example) {
	fmt.Println(Red, "rspec", example.FilePath + ":" + strconv.Itoa(example.LineNumber), Cyan, example.FullDescription)
}

func (r Result) summaryTextColor() string {
	if r.Summary.FailureCount + r.Summary.ErrorsOutsideOfExamplesCount > 0 {
		return Red
	} else if r.Summary.PendingCount > 0 {
		return Yellow
	} else {
		return Green
	}
}

// jsonToResult intakes the json output of the rspec subprocess and returns a Result struct
func jsonToResult(out []byte) Result {
	result := Result{}
	err := json.Unmarshal(out, &result)
	if err != nil {
		log.Fatalln("couldn't unmarshal data", "error:", err, "output:", out)
	}
	return result
}
