package main

import "testing"

func TestMerge(t *testing.T) {
	result := Result{
		Examples: []Example{ Example{Status: "failed"} },
		Summary: Summary{ExampleCount: 1, FailureCount: 1},
	}
	result2 := Result{
		Examples: []Example{ Example{Status: "failed"} },
		Summary: Summary{ExampleCount: 1, FailureCount: 1},
	}
	result.merge(result2)
	if len(result.Examples) != 2 {
		t.Error("expected 2 examples received", result.Summary.FailureCount)
	}
	if result.Summary.FailureCount != 2 {
		t.Error("expected failure count of 2 received count of", result.Summary.FailureCount)
	}
}