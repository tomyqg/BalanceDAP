#!/bin/bash
set -eu

echo "=== Path tests ==="
rm -rf blocks
tests/test.py << TEST
    lfs_format(&lfs, &cfg) => 0;
TEST

tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_mkdir(&lfs, "tea") => 0;
    lfs_mkdir(&lfs, "coffee") => 0;
    lfs_mkdir(&lfs, "soda") => 0;
    lfs_mkdir(&lfs, "tea/hottea") => 0;
    lfs_mkdir(&lfs, "tea/warmtea") => 0;
    lfs_mkdir(&lfs, "tea/coldtea") => 0;
    lfs_mkdir(&lfs, "coffee/hotcoffee") => 0;
    lfs_mkdir(&lfs, "coffee/warmcoffee") => 0;
    lfs_mkdir(&lfs, "coffee/coldcoffee") => 0;
    lfs_mkdir(&lfs, "soda/hotsoda") => 0;
    lfs_mkdir(&lfs, "soda/warmsoda") => 0;
    lfs_mkdir(&lfs, "soda/coldsoda") => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Root path tests ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_stat(&lfs, "tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "/tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;

    lfs_mkdir(&lfs, "/milk1") => 0;
    lfs_stat(&lfs, "/milk1", &info) => 0;
    strcmp(info.name, "milk1") => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Redundant slash path tests ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_stat(&lfs, "/tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "//tea//hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "///tea///hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;

    lfs_mkdir(&lfs, "///milk2") => 0;
    lfs_stat(&lfs, "///milk2", &info) => 0;
    strcmp(info.name, "milk2") => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Dot path tests ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_stat(&lfs, "./tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "/./tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "/././tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "/./tea/./hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;

    lfs_mkdir(&lfs, "/./milk3") => 0;
    lfs_stat(&lfs, "/./milk3", &info) => 0;
    strcmp(info.name, "milk3") => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Dot dot path tests ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_stat(&lfs, "coffee/../tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "tea/coldtea/../hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "coffee/coldcoffee/../../tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "coffee/../soda/../tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;

    lfs_mkdir(&lfs, "coffee/../milk4") => 0;
    lfs_stat(&lfs, "coffee/../milk4", &info) => 0;
    strcmp(info.name, "milk4") => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Trailing dot path tests ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_stat(&lfs, "tea/hottea/", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "tea/hottea/.", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "tea/hottea/./.", &info) => 0;
    strcmp(info.name, "hottea") => 0;
    lfs_stat(&lfs, "tea/hottea/..", &info) => 0;
    strcmp(info.name, "tea") => 0;
    lfs_stat(&lfs, "tea/hottea/../.", &info) => 0;
    strcmp(info.name, "tea") => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Root dot dot path tests ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_stat(&lfs, "coffee/../../../../../../tea/hottea", &info) => 0;
    strcmp(info.name, "hottea") => 0;

    lfs_mkdir(&lfs, "coffee/../../../../../../milk5") => 0;
    lfs_stat(&lfs, "coffee/../../../../../../milk5", &info) => 0;
    strcmp(info.name, "milk5") => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Root tests ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_stat(&lfs, "/", &info) => 0;
    info.type => LFS_TYPE_DIR;
    strcmp(info.name, "/") => 0;

    lfs_mkdir(&lfs, "/") => LFS_ERR_EXIST;
    lfs_file_open(&lfs, &file[0], "/", LFS_O_WRONLY | LFS_O_CREAT)
        => LFS_ERR_ISDIR;

    // more corner cases
    lfs_remove(&lfs, "") => LFS_ERR_INVAL;
    lfs_remove(&lfs, ".") => LFS_ERR_INVAL;
    lfs_remove(&lfs, "..") => LFS_ERR_INVAL;
    lfs_remove(&lfs, "/") => LFS_ERR_INVAL;
    lfs_remove(&lfs, "//") => LFS_ERR_INVAL;
    lfs_remove(&lfs, "./") => LFS_ERR_INVAL;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Sketchy path tests ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_mkdir(&lfs, "dirt/ground") => LFS_ERR_NOENT;
    lfs_mkdir(&lfs, "dirt/ground/earth") => LFS_ERR_NOENT;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Superblock conflict test ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    lfs_mkdir(&lfs, "littlefs") => 0;
    lfs_remove(&lfs, "littlefs") => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Max path test ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    memset(buffer, 'w', LFS_NAME_MAX+1);
    buffer[LFS_NAME_MAX+2] = '\0';
    lfs_mkdir(&lfs, (char*)buffer) => LFS_ERR_NAMETOOLONG;
    lfs_file_open(&lfs, &file[0], (char*)buffer,
            LFS_O_WRONLY | LFS_O_CREAT) => LFS_ERR_NAMETOOLONG;

    memcpy(buffer, "coffee/", strlen("coffee/"));
    memset(buffer+strlen("coffee/"), 'w', LFS_NAME_MAX+1);
    buffer[strlen("coffee/")+LFS_NAME_MAX+2] = '\0';
    lfs_mkdir(&lfs, (char*)buffer) => LFS_ERR_NAMETOOLONG;
    lfs_file_open(&lfs, &file[0], (char*)buffer,
            LFS_O_WRONLY | LFS_O_CREAT) => LFS_ERR_NAMETOOLONG;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Really big path test ---"
tests/test.py << TEST
    lfs_mount(&lfs, &cfg) => 0;
    memset(buffer, 'w', LFS_NAME_MAX);
    buffer[LFS_NAME_MAX+1] = '\0';
    lfs_mkdir(&lfs, (char*)buffer) => 0;
    lfs_remove(&lfs, (char*)buffer) => 0;
    lfs_file_open(&lfs, &file[0], (char*)buffer,
            LFS_O_WRONLY | LFS_O_CREAT) => 0;
    lfs_file_close(&lfs, &file[0]) => 0;
    lfs_remove(&lfs, (char*)buffer) => 0;

    memcpy(buffer, "coffee/", strlen("coffee/"));
    memset(buffer+strlen("coffee/"), 'w', LFS_NAME_MAX);
    buffer[strlen("coffee/")+LFS_NAME_MAX+1] = '\0';
    lfs_mkdir(&lfs, (char*)buffer) => 0;
    lfs_remove(&lfs, (char*)buffer) => 0;
    lfs_file_open(&lfs, &file[0], (char*)buffer,
            LFS_O_WRONLY | LFS_O_CREAT) => 0;
    lfs_file_close(&lfs, &file[0]) => 0;
    lfs_remove(&lfs, (char*)buffer) => 0;
    lfs_unmount(&lfs) => 0;
TEST

echo "--- Results ---"
tests/stats.py
