echo "##teamcity[testSuiteStarted name='yml']"

for file in `find share/mlt -type f -name \*.yml`; do
	file_name=${file##*/}
	service_type=${file_name%%%%_*}
	service_name=${file_name%*.yml}
	service_name=${service_name#*_}
	test_name=$service_type.$service_name

	echo "##teamcity[testStarted name='$test_name' captureStandardOutput='true']"
	kwalify -f share/mlt/metaschema.yaml $file > /dev/null;
	if [ $? -ne 0 ]; then
		echo "##teamcity[testFailed name=$test_name' message='failed to run kwalify -f share/mlt/metaschema.yaml $file']"
	fi

	./melt -query $service_type=$service_name > /dev/null;
	if [ $? -ne 0 ]; then
		echo "##teamcity[testFailed name='$test_name' message='failed to run melt -query $service_type=$service_name']"
	fi
	echo "##teamcity[testFinished name='$test_name']"
done

echo "##teamcity[testSuiteFinished name='yml']"
