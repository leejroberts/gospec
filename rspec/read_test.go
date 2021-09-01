package rspec

import (
	"testing"
)

func TestGetItPositions(t *testing.T) {
	filePath := "./testdata/spec.rb"
	itPositions := getItPositions(filePath)
	expectedItPositions := []int{30, 44, 54, 58, 68, 77, 86, 102, 106, 121,
		125, 137, 141, 162, 166, 176, 195, 199, 207, 215, 219, 232}
	if len(itPositions) != len(expectedItPositions) {
		t.Error("expect it position count: ", len(expectedItPositions),
			"actual: ", len(itPositions))
	}
	if areIdentical(itPositions, expectedItPositions) == false {
		t.Error("found positions: ", itPositions)
		t.Error("expected positions: ", expectedItPositions)
	}
}

func areIdentical(itPositions []int, expectedItPositions []int) bool {
	for i, lineNumber := range expectedItPositions {
		if itPositions[i] != lineNumber {
			return false
		}
	}
	return true
}
