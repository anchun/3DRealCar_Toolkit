# source ~/.bashrc
dataset_dir=$1
if [ -z ${dataset_dir} ]; then
    echo "Must give dataset_dir"
    exit 0;
fi
cd "$(dirname "$0")"
total=$(find "$dataset_dir" -maxdepth 1 -mindepth 1 -type d | wc -l)
count=0
find "$dataset_dir" -maxdepth 1 -mindepth 1 -type d | while read dir; do
    count=$((count + 1))
    dataset_name=$(basename "$dir")
    echo "[$count/$total]Processing dataset: $dataset_name"
    ./process.sh $dataset_name $dataset_dir
    echo "[$count/$total]Processing done: $dataset_name"
done

