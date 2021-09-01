package rspec

import (
	"regexp"
)

//getItPositions returns a slice of integers indicating the line number (1 indexed) on which all it statement are found
func getItPositions(filePath string) []int {
	itRe := regexp.MustCompile(`^\s*x?(it|it_behaves_like)\s`) // captures it and xit blocks
	lines := readFileToSlice(filePath)
	var itPositions []int
	for i, line := range lines {
		if itRe.MatchString(line) {
			itPositions = append(itPositions, i+1)
		}
	}
	return itPositions
}
