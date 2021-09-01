package main

import (
	"encoding/json"
	"fmt"
	"log"
	"strconv"
	"strings"
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
	fmt.Println(Red, "rspec", example.FilePath+":"+strconv.Itoa(example.LineNumber), Cyan, example.FullDescription)
}

func (r Result) summaryTextColor() string {
	if r.Summary.FailureCount+r.Summary.ErrorsOutsideOfExamplesCount > 0 {
		return Red
	} else if r.Summary.PendingCount > 0 {
		return Yellow
	} else {
		return Green
	}
}

// jsonToResult intakes the json output of the rspec subprocess and returns a Result struct
// If the result fails to return valid json it's often related to a need to run migrations
// when migrations need to be run, the response is a string, not json
func jsonToResult(out []byte) Result {
	result := Result{}
	if !json.Valid(out) {
		out = cleanJson(out) // non json surrounding json may need to be stripped from rspec json return values
	}
	err := json.Unmarshal(out, &result)
	if err != nil {
		log.Fatalln("Invalid JSON response", "\nerror: ", err, "\n"+string(out))
	}
	return result
}

// cleanJson removes intermittent
func cleanJson(out []byte) []byte {
	result := string(out)
	startI := strings.Index(result, "{")
	endI := strings.LastIndex(result, "}")

	result = result[startI : endI+1]
	byteResult := []byte(result)
	if json.Valid(byteResult) {
		return byteResult
	} else {
		return out
	}
}
