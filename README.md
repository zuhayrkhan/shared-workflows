# shared-workflows
Shared workflows and actions

## determine-minimal-project-list

This action uses a number of bash script to trigger various elements of maven and other processing
to derive a minimal list of maven projects (modules) that need to be built given the changes
shown to it.

### Usage:

#### example step to determine changed files:

    - name: Derive changed files
      id: derive-changed-files
      run: |
        base_ref=${{ github.event.before }}
        head_ref=${{ github.sha }}
        changed_files=$(git diff --name-only $base_ref $head_ref | tr '\n' ' ')
        echo "changed_files=$changed_files" >> $GITHUB_OUTPUT

#### example step to trigger:

    - name: Determine minimal project list
      id: determine-minimal-project-list
      uses: zuhayrkhan/shared-workflows/actions/determine-minimal-project-list@master
      with:
        changed_files: ${{ steps.derive-changed-files.outputs.changed_files }}

#### example step to consume output:

    - name: Build with Maven
      run: |
        if [[ "${{ steps.determine-minimal-project-list.outputs.project_list }}" != "" ]]; then
          mvn -B package -pl ${{ steps.determine-minimal-project-list.outputs.project_list }} -am --file pom.xml
        fi
