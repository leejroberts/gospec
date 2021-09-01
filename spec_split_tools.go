package main

import (
	"strconv"
	"strings"
)

// splitSpecsRotating splits the specs for all files given via "rotating" (each it goes to a different group)
// For example, if the max split was 4 and a spec file had 4 specs, each spec run would get 1 spec.
func splitSpecsRotating(files []string, maxSplit int) [][]string {
	groupIndex := 0
	var specGroups [][]string
	for _, file := range files {
		for _, specs := range splitFileRotating(file, maxSplit) {
			if groupIndex >= maxSplit {
				groupIndex = 0
			}
			if len(specGroups) > groupIndex {
				specGroups[groupIndex] = append(specGroups[groupIndex], specs)
			} else {
				specGroups = append(specGroups, []string{specs})
			}
			groupIndex++
		}
	}
	return specGroups
}

// splitFileRotating finds all the "it" statements in an rspec file and splits them into chunks of runnable specs.
// the split method rotates so each it goes to a different group until the max is hit, then starts over.
func splitFileRotating(file string, maxSplit int) []string {
	splitIndex := 0
	var specSets []string
	for _, itLineNumber := range getItPositions(file) {
		if splitIndex >= maxSplit {
			splitIndex = 0
		}
		if len(specSets) > splitIndex {
			specSets[splitIndex] += ":" + strconv.Itoa(itLineNumber)
		} else {
			newSpecSet := strings.TrimSpace(file) + ":" + strconv.Itoa(itLineNumber)
			specSets = append(specSets, newSpecSet)
		}
		splitIndex++
	}
	return specSets
}
