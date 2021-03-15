package main

import (
	"bufio"
	"io/ioutil"
	"log"
	"os"
	"strings"
)

// readFileToSlice reads a file... to a slice
func readFileToSlice(filePath string) []string {
	file, err := os.Open(filePath)
	if err != nil {
		log.Fatal(err)
	}
	reader := bufio.NewReader(file)
	contents, err2 := ioutil.ReadAll(reader)
	_ = file.Close()
	if err2 != nil {
		log.Fatal(err2)
	}
	return strings.Split(string(contents), "\n")
}
