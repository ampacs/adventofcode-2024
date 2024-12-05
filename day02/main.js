const fs = require('fs');

const data = fs.readFileSync('day02/input.txt', 'utf-8');

const lines = data.trim().split('\n');

let safeLevels = 0;

function checkSortOrder(arr) {
    const isAscending = arr.every((val, i, array) => i == 0 || array[i - 1] <= val );
    const isDescending = arr.every((val, i, array) => i == 0 || array[i - 1] >= val);

    return isDescending || isAscending
}

function checkAdjacent(arr) {
    for (let i = 0; i < arr.length; i++) {
        if (Math.abs(arr[i] - arr[i + 1]) < 1 || Math.abs(arr[i] - arr[i + 1]) > 3) {
            return false
        }
    }
    return true
}

function isValid(arr) {
    if (checkSortOrder(arr) && checkAdjacent (arr)) return true;
    for (let i = 0; i < arr.length; i++) {
        const modifiedArr = [...arr.slice(0, i), ...arr.slice(i + 1)];
        if (checkSortOrder(modifiedArr) && checkAdjacent(modifiedArr)) return true;
    }
    return false;
}

lines.map(row => {
    const levels = row.split(' ').map(Number);
    const sortOrder = checkSortOrder(levels);
    if (!sortOrder) {
        return
    }
    checkAdjacent(levels) ? safeLevels++ : null;
});

let safeReportsPart2 = 0;

reports = []
lines.map(row => {
    const levels = row.split(' ').map(Number);
    if (isValid(levels)) {
        reports.push(levels)
        safeReportsPart2++;
    }
})

console.log("Solution of part 1: ", safeLevels);
console.log("Solution of part 2: ", safeReportsPart2);

fs.writeFileSync('day02/output.txt', reports.map(levels => levels.join(' ')).join('\n'), {
    encoding: 'utf-8'
});
