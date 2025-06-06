## Preperation
```
# install colmap
apt-get install colmap ffmpeg

conda create -n 3drealcar python=3.10
conda activate 3drealcar
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
# install some python package
pip install colorama plyfile open3d kornia tqdm easydict imageio imageio[ffmpeg] opencv-python-headless

# other you need install GroudingDino and SAM
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth && mv sam_vit_h_4b8939.pth resources/models/
pip install submodules/GroundingDINO
pip install supervision segment_anything
```


## Run
```
# data path structure example: 
# ~/data/3drealcar/$DATASET_NAME/
# for example: ~/data/3drealcar/2024_06_04_13_44_39

export DATASET_NAME=2024_06_04_13_44_39

# Preprocess progress: colmap -> segmentation -> pcd_clean -> pcd_standard -> pcd_rescale -> processed

# colmap: use colmap to extract camera intrinsics and extrinsics.
./bash/pipeline.sh $DATASET_NAME dataset

# segmentation: use SAM to extract alpha for car. Should be run after colmap.
./bash/pipeline.sh $DATASET_NAME segmentation

# pcd_clean: use alpha extracted by SAM to clean point cloud. Should be run after segmentation.
./bash/pipeline.sh $DATASET_NAME pcd_clean

# pcd_standard: use PCA to find possible standarized coordinates. CHECKING REQUIRED since may be wrong. Should be run after pcd_clean.
./bash/pipeline.sh $DATASET_NAME pcd_standard

# pcd_rescale: use PCA calculated by ARKit camera extrinsics to extract scales between colmap camera extrinsics and arkit's. Should be run after pcd_standard.
./bash/pipeline.sh $DATASET_NAME pcd_rescale

# make the final processed folder
./bash/pipeline.sh $DATASET_NAME processed

# clean the colmap_processed folder
./bash/pipeline.sh $DATASET_NAME clean

```
