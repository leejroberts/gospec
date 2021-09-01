package main

import (
	"bufio"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
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

// getAllSpecFiles crawls through the passed in slice of files and directories
// returns all the spec files
func getAllSpecFiles(filesOrDirectories []string) []string {
	files := []string{}
	for _, fileOrDirectory := range filesOrDirectories {
		if isADirectory(fileOrDirectory) {
			files = append(files, getFilesFromDirectory(fileOrDirectory)...)
		}
		if isRspecFile(fileOrDirectory) {
			files = append(files, fileOrDirectory)
		}
	}
	return files
}

func isRspecFile(fileName string) bool {
	return filepath.Ext(fileName) == ".rb" && strings.Contains(fileName, "_spec")
}

func isADirectory(fileOrDirectoryName string) bool {
	return filepath.Ext(fileOrDirectoryName) == ""
}

// getFilesFromDirectory walks the given directory and returns all spec files found
func getFilesFromDirectory(directory string) []string {
	files := []string{}

	err := filepath.Walk(directory, func(fileOrDirectory string, info os.FileInfo, err error) error {
		if err != nil {
			log.Fatal(err)
		}
		if isRspecFile(fileOrDirectory) {
			files = append(files, fileOrDirectory)
		}
		return nil
	})
	if err != nil {
		log.Fatalln(err)
	}
	return files
}
