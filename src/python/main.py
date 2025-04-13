from pybioimage.utils import find_files
from pybioimage.aggregation import Analyzer

from pathlib import Path
from functools import partial
from concurrent.futures import ProcessPoolExecutor
import multiprocessing
from threading import Thread
from queue import Queue
import psutil
import math
from datetime import datetime

from skimage import io
import logging
import logging.handlers
import logging.config


# Variables to control behavior of analysis.
INPUT: Path = Path("data", "raw")
OUTPUT: Path = Path("data", "processed")
LOGLEVEL: int = logging.DEBUG
LOGGING_CONFIG = {
    "version": 1,
    "formatters": {
        "detailed": {
            "class": "logging.Formatter",
            "format": "%(asctime)s %(name)-15s %(levelname)-8s %(processName)-15s %(message)s",
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": "DEBUG",
            "formatter": "detailed",
        },
        "file": {
            "class": "logging.FileHandler",
            "level": "INFO",
            "filename": str(Path("log", datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + ".log")),
            "mode": "w",
            "formatter": "detailed",
        },
    },
    "loggers": {"pybioimage": {"level": "DEBUG", "propagate": True}},
    "root": {"level": "DEBUG", "handlers": ["console", "file"]},
}


def determine_cores(images: int, max_cores: int = 1) -> int:
    """Find a reasonable number of cores to use for analysis

    Parameters
    ----------
    images : int
        The number of images to be analyzed.
    max_cores : int
        The maximal number of cores allowed to use.

    Returns
    -------
    int
        Number of cores to be used for analysis. This can be less than the `max_cores` if there is
        no advantage in using more.

    Notes
    -----
    Consider you have 18 images and want to use at most 12 cores. This is less than the number of
    images, i.e., some cores have to analyze 2 images and this will define execution time. With 9
    cores each core runs analysis for 2 images resulting in more or less the same execution time
    than 12 cores but creating less overhead.
    In addition, the number of cores will never be greater than the number of physical cores as this
    doesn't give any advantage (even with hyperthreading).
    """

    # Choose a meaningful number of cores.
    real_cores = psutil.cpu_count(logical=False)

    if max_cores > real_cores:
        max_cores = real_cores

    if images <= max_cores:
        max_cores = images
    else:
        max_cores = min(math.ceil(images / 2), max_cores)

    return max_cores


def setup_main_logger() -> tuple[logging.Logger, Queue, Thread]:
    """Create and start the multiprocessing log queue and its consumer thread.

    Returns
    -------
    tuple[logging.Logger, Queue, Thread]
        The logger, log queue, and the thread that consumes it.
    """

    logging.config.dictConfig(LOGGING_CONFIG)
    logger = logging.getLogger()
    log_queue = multiprocessing.Manager().Queue(-1)
    thread = Thread(target=consume_log_queue, args=(log_queue,))
    thread.start()

    return logger, log_queue, thread


def setup_worker_logger(log_queue: Queue) -> logging.Logger:
    """Initialize a logger for the current sub-process.

    Parameters
    ----------
    log_queue : Queue
        A Queue from the main process to which logs can be pushed. These logs will then be consumed
        by a separate function in the main process.

    Returns
    -------
    logging.Logger
        A Logger instance to which logs can be written.
    """

    queue_handler = logging.handlers.QueueHandler(log_queue)
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    logger.handlers.clear()
    logger.addHandler(queue_handler)

    return logger


def consume_log_queue(log_queue):
    """Consumes logs pushed to the log queue that is shared between processes

    Parameters
    ----------
    log_queue : multiprocessing.Queue

    Returns
    -------
    None
    """

    while True:
        record = log_queue.get()
        if record is None:
            break
        logger = logging.getLogger(record.name)
        logger.handle(record)


def worker(
    path: str | Path,
    log_queue: multiprocessing.Queue,
    export_vis: bool = False,
    **kwargs,
) -> None:
    """A worker function for multiprocessing

    Parameters
    ----------
    path : str | Path
        The path to an image for cell aggregation analysis.
    log_queue : multiprocessing.Queue
        A queue to which logs can be pushed. The queue should be created with
        multiprocessing.Manager().Queue() instead of multiprocessing.Queue() in order to work with
        ProcessPoolExecutor.
    export_vis : bool, optional
        Flag indicating whether an image showing identified clusters and cells should be saved.
        Default is `False`.
    kwargs
        Additional keyworded arguments passed down to the `analyze()` method.
        Ignored if `analyze` is set to False.

    Returns
    -------
    None

    Notes
    -----
    This is just a small helper function because the multiprocessing module
    requires the work unit to be multiprocessed to be outsourced to its own
    function.
    """

    logger = setup_worker_logger(log_queue=log_queue)

    try:
        analyzer = Analyzer(path)
        analyzer.analyze(**kwargs)
    except Exception as error:
        logger.error("Could not analyze %s: %s", path.name, error)
        return

    path = OUTPUT.joinpath(*analyzer.path.parts[2:-1])
    path.mkdir(parents=True, exist_ok=True)

    # Save results to disk.
    analyzer.measurements.to_csv(path.joinpath("aggregations.csv"), index=False)
    if export_vis:
        io.imsave(path.joinpath("vis.png"), analyzer.visualize_segmentation())
    # mask = analyzer.extract_mask()
    # io.imsave(analyzer.path.with_name("mask.tif"), mask)


def main(max_cores: int = 1, export_vis: bool = False, **kwargs) -> None:
    """Run parallel cell aggregation analysis on microscopy images

    Parameters
    ----------
    max_cores : int, optional
        The maximum number of cores (processes) used for analysis. This is the maximal number of
        cores. The number can be reduced if there is no gain in using more cores.
    export_vis : bool, optional
    kwargs
        Additional arguments passed down to the worker function.

    Returns
    -------
    None
    """

    # Setting up a log queue, to which all subprocesses can write logs. The logs on this queue will
    # be digested by a separate thread in the main process.
    logger, log_queue, log_consumer_thread = setup_main_logger()

    logger.info("Starting...")

    files = list(find_files(INPUT, pattern="tilescan_projection.tif$"))
    max_cores = determine_cores(images=len(files), max_cores=max_cores)

    logger.info("Found %d images. Use %d cores.", len(files), max_cores)

    # Setting up the actual multiprocessing.
    with ProcessPoolExecutor(max_workers=max_cores) as executor:
        partial_worker = partial(worker, log_queue=log_queue, export_vis=export_vis, **kwargs)
        executor.map(partial_worker, files)

    logger.info("Finished successfully.")

    # Stop consume loop by pushing `None` to queue.
    log_queue.put(None)
    log_consumer_thread.join()


if __name__ == "__main__":

    main(max_cores=12)
