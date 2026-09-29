#!/usr/bin/env node
// Renumber migrations to unique sequential 001-XXX
// Run from backend/migrations/

const fs = require('fs');
const path = require('path');

const migrationsDir = __dirname;

// Get all .sql files (exclude .down.sql)
const allFiles = fs.readdirSync(migrationsDir)
  .filter(f => f.endsWith('.sql') && !f.endsWith('.down.sql'))
  .sort((a, b) => {
    // Sort by current prefix number, then alphabetically
    const getPrefix = f => parseInt(f.split('_')[0], 10) || 0;
    const pa = getPrefix(a);
    const pb = getPrefix(b);
    if (pa !== pb) return pa - pb;
    return a.localeCompare(b);
  });

console.log('=== Current files (sorted by prefix) ===');
allFiles.forEach((f, i) => console.log(`${String(i+1).padStart(3,'0')}: ${f}`));

// Create new names: 001_, 002_, 003_, ...
const renameMap = {};
allFiles.forEach((oldName, i) => {
  const newPrefix = String(i + 1).padStart(3, '0');
  // Keep the descriptive part after the first underscore
  const parts = oldName.split('_');
  parts.shift(); // remove old prefix
  const newName = `${newPrefix}_${parts.join('_')}`;
  renameMap[oldName] = newName;
});

console.log('\n=== Rename map ===');
Object.entries(renameMap).forEach(([old, newn]) => {
  if (old !== newn) console.log(`${old}  ->  ${newn}`);
});

// Execute renames
console.log('\n=== Executing renames ===');
Object.entries(renameMap).forEach(([old, newn]) => {
  if (old !== newn) {
    const oldPath = path.join(migrationsDir, old);
    const newPath = path.join(migrationsDir, newn);
    fs.renameSync(oldPath, newPath);
    console.log(`✅ Renamed: ${old} -> ${newn}`);
  }
});

// Also rename the .down.sql files to match
console.log('\n=== Renaming .down.sql files ===');
const downFiles = fs.readdirSync(migrationsDir).filter(f => f.endsWith('.down.sql'));
downFiles.forEach(downFile => {
  // Find matching up file
  const baseName = downFile.replace('.down.sql', '.sql');
  const newBase = renameMap[baseName];
  if (newBase) {
    const newDown = newBase.replace('.sql', '.down.sql');
    const oldPath = path.join(migrationsDir, downFile);
    const newPath = path.join(migrationsDir, newDown);
    fs.renameSync(oldPath, newPath);
    console.log(`✅ Renamed down: ${downFile} -> ${newDown}`);
  }
});

console.log('\n=== Final file list ===');
fs.readdirSync(migrationsDir)
  .filter(f => f.endsWith('.sql') && !f.endsWith('.down.sql'))
  .sort()
  .forEach((f, i) => console.log(`${String(i+1).padStart(3,'0')}: ${f}`));